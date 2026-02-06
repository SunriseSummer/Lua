// Test: Loops - while, for

// while loop
var sum = 0
var i = 1
while i <= 10 {
  sum = sum + i
  i = i + 1
}
println("sum 1..10 = ${sum}")  // 55

// while with parenthesized condition
var count = 0
while (count < 5) {
  count = count + 1
}
println("count = ${count}")  // 5

// Numeric for loop
var total = 0
for j = 1, 100 {
  total = total + j
}
println("sum 1..100 = ${total}")  // 5050

// For loop with step
var evens = 0
for k = 0, 10, 2 {
  evens = evens + k
}
println("sum evens 0..10 = ${evens}")  // 30

// Generic for loop (using pairs/ipairs)
let t = {10, 20, 30, 40, 50}
var tsum = 0
for idx, val in ipairs(t) {
  tsum = tsum + val
}
println("array sum = ${tsum}")  // 150

// Break in loop
var found = 0
for n = 1, 100 {
  if n * n > 50 {
    found = n
    break
  }
}
println("first n where n*n > 50: ${found}")  // 8

// Nested loops
var matrix_sum = 0
for r = 1, 3 {
  for c = 1, 3 {
    matrix_sum = matrix_sum + r * c
  }
}
println("matrix sum = ${matrix_sum}")  // 36

println("PASS: 03_loops")
