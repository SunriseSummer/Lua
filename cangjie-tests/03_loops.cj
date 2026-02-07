// Test: Loops - while, for
// Validates while loops, for loops with inclusive/exclusive ranges, step ranges,
// array iteration by index, break statements, and nested loops.

// -- Section: while loop --
var sum = 0
var i = 1
while (i <= 10) {
  sum = sum + i
  i = i + 1
}
if (sum != 55) { println("FAIL: while sum expected 55, got ${sum}"); return () }

// -- Section: for with inclusive range --
var total = 0
for (j in 1..=100) {
  total = total + j
}
if (total != 5050) { println("FAIL: inclusive range sum expected 5050, got ${total}"); return () }

// -- Section: for with exclusive range --
var total2 = 0
for (j in 1..101) {
  total2 = total2 + j
}
if (total2 != 5050) { println("FAIL: exclusive range sum expected 5050, got ${total2}"); return () }

// -- Section: for with step --
var evens = 0
for (k in 0..=10:2) {
  evens = evens + k
}
if (evens != 30) { println("FAIL: step range evens expected 30, got ${evens}"); return () }

// -- Section: array iteration by index --
let t = [10, 20, 30, 40, 50]
var tsum = 0
for (i in 0..t.size) {
  tsum = tsum + t[i]
}
if (tsum != 150) { println("FAIL: array sum expected 150, got ${tsum}"); return () }

// -- Section: break in loop --
var found = 0
for (n in 1..=100) {
  if (n * n > 50) {
    found = n
    break
  }
}
if (found != 8) { println("FAIL: break/found expected 8, got ${found}"); return () }

// -- Section: nested loops --
var matrix_sum = 0
for (r in 1..=3) {
  for (c in 1..=3) {
    matrix_sum = matrix_sum + r * c
  }
}
if (matrix_sum != 36) { println("FAIL: matrix_sum expected 36, got ${matrix_sum}"); return () }

println("PASS: 03_loops")
