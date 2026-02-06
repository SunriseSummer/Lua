// Test: Loops - while, for

// while loop (parentheses required)
var sum = 0
var i = 1
while (i <= 10) {
  sum = sum + i
  i = i + 1
}
println("sum 1..=10 = ${sum}")  // 55

// Numeric for with inclusive range
var total = 0
for (j in 1..=100) {
  total = total + j
}
println("sum 1..=100 = ${total}")  // 5050

// Numeric for with exclusive range
var total2 = 0
for (j in 1..101) {
  total2 = total2 + j
}
println("sum 1..101 = ${total2}")  // 5050

// For loop with step
var evens = 0
for (k in 0..=10:2) {
  evens = evens + k
}
println("sum evens 0..=10:2 = ${evens}")  // 30

// Generic for loop with ipairs (array iteration)
let t = [10, 20, 30, 40, 50]
var tsum = 0
for (idx, val in ipairs(t)) {
  tsum = tsum + val
}
println("array sum = ${tsum}")  // 150

// Iterating by index over array
var tsum2 = 0
for (i in 1..=t.size) {
  tsum2 = tsum2 + t[i]
}
println("array sum by index = ${tsum2}")  // 150

// Break in loop
var found = 0
for (n in 1..=100) {
  if (n * n > 50) {
    found = n
    break
  }
}
println("first n where n*n > 50: ${found}")  // 8

// Nested loops
var matrix_sum = 0
for (r in 1..=3) {
  for (c in 1..=3) {
    matrix_sum = matrix_sum + r * c
  }
}
println("matrix sum = ${matrix_sum}")  // 36

println("PASS: 03_loops")
