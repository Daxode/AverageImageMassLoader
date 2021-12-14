package average_image_mass_loader

import "core:c"
import "core:fmt"
import "core:core/os"
import "vendor:stb/image"

main::proc()
{
    w, h, channels: c.int
    icon_bytes := image.load("resources/DaxodeProfile.png",&w,&h, &channels, 0)
    defer image.image_free(icon_bytes)
    
}