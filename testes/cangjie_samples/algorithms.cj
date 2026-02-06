global <const> *

print("cangjie sample: sorted values")

let sorted_numbers: Table = {1, 2, 3, 4, 5}
assert(sorted_numbers[1] == 1)
assert(sorted_numbers[5] == 5)
println("sorted first $(sorted_numbers[1]) last $(sorted_numbers[5])")

let fib_a = 1
let fib_b = 1
let fib_c = fib_a + fib_b
let fib_d = fib_b + fib_c
let fib_result = fib_c + fib_d
assert(fib_result == 5)
