package probability_calc
import "core:math/rand"
import "core:fmt"

main::proc()
{
    prob := [?]f32 {0.9, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3}
    
    sum0to14: f32 = 0
    for val in prob {sum0to14 += val}
    sum2to6: f32 = 0
    for val in prob[2:6] {sum2to6 += val}

    random := rand.create(0)
    sum : f64 = 0
    for i in 0..1000000 {
        val_0 := rand.float32_range(0,sum0to14, &random)
        check_sum_0: f32 = 0
        elem0 := 0
        for prob_val, i in prob {
            check_sum_0 += prob_val
            if val_0 <= check_sum_0 {
                elem0 = i
                break
            }
        }

        val_1 := rand.float32_range(0,sum2to6, &random)
        check_sum_1: f32 = 0
        elem1 := 0
        for prob_val, i in prob[2:6] {
            check_sum_1 += prob_val
            if val_1 <= check_sum_1 {
                elem1 = i+2
                break
            }
        }

        sum += f64(u8(elem0>=elem1))
    }

    fmt.println(sum/f64(1000000))
}