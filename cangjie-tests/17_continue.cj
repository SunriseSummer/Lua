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
if (sum != 25) { println("FAIL: sum expected 25, got ${sum}"); return () }

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
if (result != 37) { println("FAIL: result expected 37, got ${result}"); return () }

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
if (total != 12) { println("FAIL: total expected 12, got ${total}"); return () }

// --- continue with complex condition ---
var count: Int64 = 0
for (k in 1..=20) {
  if (k % 2 == 0 && k % 3 == 0) {
    continue
  }
  count = count + 1
}
if (count != 17) { println("FAIL: count expected 17, got ${count}"); return () }

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
if (s != "1245") { println("FAIL: s expected '1245', got '${s}'"); return () }

println("PASS: 17_continue")
