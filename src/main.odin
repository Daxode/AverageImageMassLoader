package probability_calc
import "core:math/rand"
import "core:fmt"
import rl "vendor:raylib"
import "core:thread"
import "core:strconv"
import "core:strings"
import "core:math"
import "core:time"
import "core:os"

main::proc()
{
    rl.InitWindow(2048,1024,"Probability Viz")
    if len(os.args) < 2 {rl.SetTargetFPS(100)}

    update_current_average_instance_data := Update_Current_Average_Data{true, 0, 0}
    update_current_average_instance := thread.create(update_current_average_job);
    if update_current_average_instance != nil {
        update_current_average_instance.init_context = context
        update_current_average_instance.data = &update_current_average_instance_data
        thread.start(update_current_average_instance)
    }

    probabilities_buffer := make([dynamic]f32, 0, 1000000)
    defer delete(probabilities_buffer)
    for !rl.WindowShouldClose() {
        // Update data
        append(&probabilities_buffer, f32(update_current_average_instance_data.current_average))

        // Drawing
        rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)
        for probability, i in probabilities_buffer {
            rl.DrawCircle(i32(f32(i+1)*(f32(rl.GetScreenWidth())/f32(len(probabilities_buffer)+1))), 
                i32(math.lerp(f32(5), f32(rl.GetScreenHeight()-5), probability)), 
                5, rl.WHITE,
            )
        }

        buf: [32]byte
        rl.DrawText(strings.unsafe_string_to_cstring(strconv.append_uint(buf[:], update_current_average_instance_data.amount_run,10)), 10, 10, 72, rl.BLUE)

        rl.EndDrawing()
    }

    rl.CloseWindow()
    update_current_average_instance_data.should_run = false
    thread.destroy(update_current_average_instance)
}
Update_Current_Average_Data :: struct {
    should_run: b8,
    current_average: f64,
    amount_run: u64,
}

update_current_average_job :: proc(t: ^thread.Thread) {
    data := (^Update_Current_Average_Data)(t.data)

    // Setup Probability
    prob := []f32 {0.9, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3}

    sum0to14: f32 = 0
    for val in prob {sum0to14 += val}
    sum2to6: f32 = 0
    for val in prob[2:6] {sum2to6 += val}

    random := rand.create(0) 
    summed_eval: u64 = 0

    // Run probabilities
    if len(os.args) < 2 {
        for data.should_run {
            element_1 := get_probabilities_based_value_from_table(prob, 0, 14, sum0to14, &random)
            element_2 := get_probabilities_based_value_from_table(prob, 2,  6,  sum2to6, &random)
    
            summed_eval += u64(element_1 >= element_2)
            data.amount_run += 1
            data.current_average = f64(summed_eval)/f64(data.amount_run)
            
            time.sleep(10*time.Millisecond)
        }
    } else {
        for data.should_run {
            element_1 := get_probabilities_based_value_from_table(prob, 0, 14, sum0to14, &random)
            element_2 := get_probabilities_based_value_from_table(prob, 2,  6,  sum2to6, &random)
    
            summed_eval += u64(element_1 >= element_2)
            data.amount_run += 1
            data.current_average = f64(summed_eval)/f64(data.amount_run)
        }
    }
}

get_probabilities_based_value_from_table :: proc(probabilities: []f32, low, high:u8, max_sum_for_range: f32, random: ^rand.Rand) -> u8 {
    random_value := rand.float32_range(0, max_sum_for_range, random)
    sum: f32 = 0
    for prob_val, i in probabilities[low:high] {
        sum += prob_val
        if random_value <= sum {
            return u8(i)+low
        }
    }
    return high
}