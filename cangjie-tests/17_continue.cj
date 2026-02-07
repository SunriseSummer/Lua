// Test: continue statement in loops

// continue in for loop - skip even numbers
var sum: Int64 = 0
for (i in 1..=10) {
  if (i % 2 == 0) {
    continue
  }
  sum = sum + i
}
println(sum)  // 1+3+5+7+9 = 25

// continue in while loop - skip multiples of 3
var result: Int64 = 0
var j: Int64 = 0
while (j < 10) {
  j = j + 1
  if (j % 3 == 0) {
    continue
  }
  result = result + j
}
println(result)  // 1+2+4+5+7+8+10 = 37

// nested continue - inner loop only
var total: Int64 = 0
for (a in 1..=3) {
  for (b in 1..=3) {
    if (b == 2) {
      continue
    }
    total = total + b
  }
}
println(total)  // (1+3)*3 = 12

// continue with complex condition
var count: Int64 = 0
for (k in 1..=20) {
  if (k % 2 == 0 && k % 3 == 0) {
    continue
  }
  count = count + 1
}
println(count)  // 20 - 3 (6,12,18) = 17

// continue in while with multiple conditions
var s: String = ""
var idx: Int64 = 0
while (idx < 5) {
  idx = idx + 1
  if (idx == 3) {
    continue
  }
  s = s + tostring(idx)
}
println(s)  // 1245

println("PASS: 17_continue")
