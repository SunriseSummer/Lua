global <const> *

print("cangjie sample: sorted values")

let sorted_numbers: Table = {1, 2, 3, 4, 5}
assert(sorted_numbers[1] == 1)
assert(sorted_numbers[5] == 5)
println("sorted first $(sorted_numbers[1]) last $(sorted_numbers[5])")

let fib_zero = 0
let fib_one = 1
let fib_two = fib_zero + fib_one
let fib_three = fib_one + fib_two
let fib_four = fib_two + fib_three
let fib_five = fib_three + fib_four
assert(fib_five == 5)
