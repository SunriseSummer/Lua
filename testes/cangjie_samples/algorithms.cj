global <const> *

print("cangjie sample: algorithms")

let numbers: Table = {1, 2, 3, 4, 5}
assert(numbers[1] == 1)
assert(numbers[5] == 5)
println("sorted first $(numbers[1]) last $(numbers[5])")

let fib3 = 2
let fib4 = 3
let fib5 = fib3 + fib4
assert(fib5 == 5)
