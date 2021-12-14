package probability_calc
import "core:math/rand"
import "core:fmt"

main::proc()
{
    prob := []f32 {0.9, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3}
    
    sum0to14: f32 = 0
    for val in prob {sum0to14 += val}
    sum2to6: f32 = 0
    for val in prob[2:6] {sum2to6 += val}

    random := rand.create(0)
    sum : f64 = 0
    for i in 0..1000000000 {
        element_1 := get_probabilities_based_value_from_table(prob, 0, 14, sum0to14, &random)
        element_2 := get_probabilities_based_value_from_table(prob, 2,  6,  sum2to6, &random)

        sum += f64(u8(element_1 >= element_2))
    }

    fmt.println(sum/f64(1000000000))
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