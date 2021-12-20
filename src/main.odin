package average_image_mass_loader

import "core:os"
import "core:c/libc"
import "core:strconv"
import "core:fmt"
import "core:strings"
import "vendor:stb/image"

main::proc()
{
    // Get cmd input
    tile_width: u32 = 16
    tile_height: u32 = 16
    input_path := "input.png"
    name := "unnammed"
    frame_rate_str := "25"
    for arg in os.args[1:] {
        switch arg[0] {
            case 'i':
                input_path = arg[2:]
            case 's':
                hit_comma := false
                width_mult, height_mult: u32 = 1, 1
                tile_width, tile_height = 0, 0
                for i: u8 = u8(len(arg)-1); i>=2; i-=1 {
                    if arg[i] == ',' {
                        hit_comma=true
                        continue
                    }
                    if hit_comma {
                        tile_height += u32(arg[i]-'0')*height_mult
                        height_mult *= 10
                    } else {
                        tile_width += u32(arg[i]-'0')*width_mult
                        width_mult *= 10
                    }
                }
            case 'f':
                frame_rate_str = arg[2:]
            case 'n':
                name = arg[2:]
        }
    }
    fmt.println(input_path, name, tile_width, tile_height, frame_rate_str)

    // Build png base
    os.make_directory("temp_delete_this_when_done",0)
    build_base_pngs_string := strings.concatenate({"ffmpeg -i ", input_path, " -vsync 0 temp_delete_this_when_done/in%03d.png"})
    libc.system(strings.clone_to_cstring(build_base_pngs_string))

    // Take png base
    temp_delete_this_when_done_handle, _ := os.open("temp_delete_this_when_done")
    build_base_png_infos, _ := os.read_dir(temp_delete_this_when_done_handle, 0)
    os.close(temp_delete_this_when_done_handle)

    // Make tiny pictures from big pictures
    my_tile_bytes := make([]u8, tile_width*tile_height*4)
    tile_amount_width, tile_amount_height: u32

    for info, it in build_base_png_infos {
        image_width, image_height, image_channel_count : libc.int
        picture_bytes := image.load(strings.clone_to_cstring(info.fullpath),&image_width, &image_height, &image_channel_count, 4)
        tile_amount_width, tile_amount_height = u32(image_width)/tile_width, u32(image_height)/tile_height

        // For every tile
        for tile_y in 0..<tile_amount_height {
            tile_y_pixel := tile_y*tile_height
            tile_y_name_buf: [32]u8
            tile_y_name := strconv.append_uint(tile_y_name_buf[:], u64(tile_y), 10)

            for tile_x in 0..<tile_amount_width {
                tile_x_pixel := tile_x*tile_width
                tile_x_name_buf: [32]u8
                tile_x_name := strconv.append_uint(tile_x_name_buf[:], u64(tile_x), 10)

                // For every pixel in tile
                for pixel_y in tile_y_pixel..<min(tile_y_pixel+tile_height, u32(image_height)) {
                    for pixel_x in tile_x_pixel..<min(tile_x_pixel+tile_width, u32(image_width)) {
                        image_pixel_index := pixel_x*u32(image_channel_count) + pixel_y*u32(image_width*image_channel_count)
                        tile_pixel_x, tile_pixel_y := pixel_x%tile_width, pixel_y%tile_height
                        tile_pixel_index := tile_pixel_x*4+ tile_pixel_y*u32(tile_width*4)
                        for i in 0..<image_channel_count {
                            my_tile_bytes[tile_pixel_index+u32(i)] = picture_bytes[image_pixel_index+u32(i)]
                        }
                    }
                }

                // Save tile
                tile_name := strings.concatenate({"temp_delete_this_when_done/",name,"_",tile_x_name,"_",tile_y_name,"_",info.name[:len(info.name)-4],".png"})
                image.write_png(strings.clone_to_cstring(tile_name),i32(tile_width),i32(tile_height),4,raw_data(my_tile_bytes),i32(tile_width*4))
            }
        }
        
        image.image_free(picture_bytes)
    }

    // Merge to gif
    os.make_directory("out",0)
    for tile_y in 0..<tile_amount_height {
        tile_y_name_buf: [32]u8
        tile_y_name := strconv.append_uint(tile_y_name_buf[:], u64(tile_y), 10)

        for tile_x in 0..<tile_amount_width {
            tile_x_name_buf: [32]u8
            tile_x_name := strconv.append_uint(tile_x_name_buf[:], u64(tile_x), 10)

            tile_name := strings.concatenate({name,"_",tile_x_name,"_",tile_y_name})
            tile_ffmpeg_path := strings.concatenate({"temp_delete_this_when_done/",tile_name,"_in%03d.png"})
            tile_create_palette := strings.concatenate({"ffmpeg -i ",tile_ffmpeg_path," -vf palettegen=reserve_transparent=1 temp_delete_this_when_done/",tile_name,"_pal.png"})
            tile_create_gif := strings.concatenate({
                "ffmpeg -framerate ",frame_rate_str,
                " -i ",tile_ffmpeg_path,
                " -i temp_delete_this_when_done/",tile_name,"_pal.png",
                " -lavfi \"paletteuse=alpha_threshold=128,scale=",strconv.append_uint(tile_x_name_buf[:],u64(tile_width),10),":",strconv.append_uint(tile_x_name_buf[:],u64(tile_height),10),"\"",
                " out/",tile_name,".gif"})
            fmt.println(tile_create_palette)
            libc.system(strings.clone_to_cstring(tile_create_palette))
            fmt.println(tile_create_gif)
            libc.system(strings.clone_to_cstring(tile_create_gif))
        }
    }

    // Remove temp_delete_this_when_done folder
    temp_path_handle, _ := os.open("temp_delete_this_when_done")
    file_infos, _ := os.read_dir(temp_path_handle, 0)
    os.close(temp_path_handle)
    for file_info in file_infos {
        os.remove(file_info.fullpath)
    }
    os.remove("temp_delete_this_when_done")
}

// Add:  // To use palette