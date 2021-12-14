package average_image_mass_loader

import "core:c"
import "core:fmt"
import "core:os"
import "vendor:stb/image"
import "core:strings"
import "core:strconv"

main::proc()
{
    // Get files in folder
    current_dir := os.get_current_directory()
    in_dir := strings.concatenate({current_dir, "\\in"})
    handle_dir, _ := os.open(in_dir)
    defer os.close(handle_dir)
    file_infos, _ := os.read_dir(handle_dir, 1024)

    // Get out file
    out_file_path := strings.concatenate({current_dir, "\\out\\out.tsv"})
    handle_file, _ := os.open(out_file_path, os.O_WRONLY|os.O_CREATE)
    defer os.close(handle_file)

    // Loop through files adding average to out file
    for file_info in file_infos {
        // Check file conditions
        if (!strings.contains(file_info.name, "HeatMap")) {continue}

        // Get image values
        w, h, channels: c.int
        image_values := image.loadf(strings.clone_to_cstring(file_info.fullpath),&w,&h, &channels, 0)
        defer image.image_free(image_values)

        // Sum all alphas
        summed_value : f32 = 0
        for i:=3; i<2048*2048*4; i+=4 { 
            summed_value += image_values[i]
        }

        // Convert to percentage float
        buf := [32]byte{}
        average_val := 100*(f64(summed_value)/f64(2048*2048))
        average_val_str := strconv.ftoa(buf[:], average_val, 'f', len(buf), 64)[1:]

        // Write to file
        line_to_write := strings.concatenate({file_info.name,"\t", average_val_str,"\n"})
        os.write_string(handle_file, line_to_write)
    }
}