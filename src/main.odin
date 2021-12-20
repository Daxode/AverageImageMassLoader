package average_image_mass_loader

import "core:c"
import "core:fmt"
import "core:os"
import "vendor:stb/image"
import "core:strings"
import "core:strconv"
import "core:thread"

main::proc()
{
    // Get files in folder
    current_dir := os.get_current_directory()
    in_dir := strings.concatenate({current_dir, "\\in"})
    handle_dir, _ := os.open(in_dir)
    file_infos, _ := os.read_dir(handle_dir, 1024)
    os.close(handle_dir)

    // Run jobs to read images
    work_on_image_pool: thread.Pool
    thread.pool_init(&work_on_image_pool, 16)
    work_on_image_data := Work_On_Image_Data{file_infos, make([]string, len(file_infos))}
    for i in 0..<30 {
        thread.pool_add_task(&work_on_image_pool,work_on_image, &work_on_image_data, i)
    }
    
    thread.pool_start(&work_on_image_pool)
    thread.pool_wait_and_process(&work_on_image_pool)

    // Make out dir
    out_path := strings.concatenate({current_dir, "\\out"})
    os.make_directory(out_path, 0)

    // Write result to file
    out_file_path := strings.concatenate({out_path, "\\out.tsv"})
    handle_file, _ := os.open(out_file_path, os.O_WRONLY|os.O_CREATE)

    for result in work_on_image_data.results {
        if result == {} {continue}
        os.write_string(handle_file, result)
    }

    // Clean up
    os.close(handle_file)
    thread.pool_destroy(&work_on_image_pool)
    delete(work_on_image_data.file_infos)
    delete(work_on_image_data.results)
}

Work_On_Image_Data :: struct {
    file_infos: []os.File_Info,
    results: []string,
}

work_on_image :: proc(t: ^thread.Task) {
    // Loop through files adding average to out file
    data := (^Work_On_Image_Data)(t.data)^
    for i in 0..<6 {
        // Get info for thread
        index := t.user_index*6+i
        file_info := data.file_infos[index]

        // Check file conditions
        if (!strings.contains(file_info.name, "HeatMap")) {continue}

        // Get image values
        w, h, channels: c.int
        image_values := image.loadf(strings.unsafe_string_to_cstring(file_info.fullpath),&w,&h,&channels, 4)
        defer image.image_free(image_values)
    
        // Sum all alphas
        summed_value : f32 = 0
        for j:=3; j<2048*2048*4; j+=4 { 
            summed_value += image_values[j]
        }
    
        // Convert to percentage float
        buf := [32]byte{}
        average_val := 100*(f64(summed_value)/f64(2048*2048))
        average_val_str := strconv.ftoa(buf[:], average_val, 'f', len(buf), 64)[1:]
    
        // Write to file
        data.results[index] = strings.concatenate({file_info.name,"\t", average_val_str,"\n"})
    }
}