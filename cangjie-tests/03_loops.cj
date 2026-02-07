dofile("cangjie-tests/_testing.cj")

// Test: Loops - while, for

// -- Section: while loop --
var sum = 0
var i = 1
while (i <= 10) {
  sum = sum + i
  i = i + 1
}
expectEq(sum, 55, "while sum 1..=10")

// -- Section: for with inclusive range --
var total = 0
for (j in 1..=100) {
  total = total + j
}
expectEq(total, 5050, "inclusive range sum")

// -- Section: for with exclusive range --
var total2 = 0
for (j in 1..101) {
  total2 = total2 + j
}
expectEq(total2, 5050, "exclusive range sum")

// -- Section: for with step --
var evens = 0
for (k in 0..=10:2) {
  evens = evens + k
}
expectEq(evens, 30, "step range evens")

// -- Section: array iteration by index --
let t = [10, 20, 30, 40, 50]
var tsum = 0
for (i in 0..t.size) {
  tsum = tsum + t[i]
}
expectEq(tsum, 150, "array sum")

// -- Section: break in loop --
var found = 0
for (n in 1..=100) {
  if (n * n > 50) {
    found = n
    break
  }
}
expectEq(found, 8, "break/found")

// -- Section: nested loops --
var matrix_sum = 0
for (r in 1..=3) {
  for (c in 1..=3) {
    matrix_sum = matrix_sum + r * c
  }
}
expectEq(matrix_sum, 36, "nested loops matrix_sum")

if (!__test_failed) {
    println("PASS: 03_loops")
}
