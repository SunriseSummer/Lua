global <const> *

print("cangjie sample: sorted values")

let sorted_numbers: Table = {1, 2, 3, 4, 5}
assert(sorted_numbers[1] == 1)
assert(sorted_numbers[5] == 5)
println("sorted first $(sorted_numbers[1]) last $(sorted_numbers[5])")

let fib_first = 1
let fib_second = 1
let fib_third = fib_first + fib_second
let fib_fourth = fib_second + fib_third
let fib_fifth = fib_third + fib_fourth
assert(fib_fifth == 5)
