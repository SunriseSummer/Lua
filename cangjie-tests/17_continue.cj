dofile("cangjie-tests/_testing.cj")

// Test: continue statement in loops
// Validates that continue correctly skips iterations in for, while, and nested loops

// --- continue in for loop - skip even numbers ---
var sum: Int64 = 0
for (i in 1..=10) {
  if (i % 2 == 0) {
    continue
  }
  sum = sum + i
}
expectEq(sum, 25, "sum of odd numbers 1..10")

// --- continue in while loop - skip multiples of 3 ---
var result: Int64 = 0
var j: Int64 = 0
while (j < 10) {
  j = j + 1
  if (j % 3 == 0) {
    continue
  }
  result = result + j
}
expectEq(result, 37, "sum skipping multiples of 3")

// --- nested continue - inner loop only ---
var total: Int64 = 0
for (a in 1..=3) {
  for (b in 1..=3) {
    if (b == 2) {
      continue
    }
    total = total + b
  }
}
expectEq(total, 12, "nested continue total")

// --- continue with complex condition ---
var count: Int64 = 0
for (k in 1..=20) {
  if (k % 2 == 0 && k % 3 == 0) {
    continue
  }
  count = count + 1
}
expectEq(count, 17, "count skipping multiples of 6")

// --- continue in while with multiple conditions ---
var s: String = ""
var idx: Int64 = 0
while (idx < 5) {
  idx = idx + 1
  if (idx == 3) {
    continue
  }
  s = s + tostring(idx)
}
expectEq(s, "1245", "string skipping idx==3")

if (!__test_failed) {
    println("PASS: 17_continue")
}
