global <const> *

print("cangjie sample: sorted values")

let sorted_numbers: Table = {1, 2, 3, 4, 5}
assert(sorted_numbers[1] == 1)
assert(sorted_numbers[5] == 5)
println("sorted first $(sorted_numbers[1]) last $(sorted_numbers[5])")

let fib1 = 1
let fib2 = 1
let fib3 = fib1 + fib2
let fib4 = fib2 + fib3
let fib5 = fib3 + fib4
assert(fib5 == 5)
