dofile("cangjie-tests/_testing.cj")

// Test: Loop boundary conditions and edge cases

// --- Section: while loop with false condition (zero iterations) ---
var count = 0
while (false) {
    count = count + 1
}
expectEq(count, 0, "while(false) zero iterations")

// --- Section: while loop single iteration ---
count = 0
var flag = true
while (flag) {
    count = count + 1
    flag = false
}
expectEq(count, 1, "while single iteration")

// --- Section: for with empty exclusive range (start == end) ---
var sum = 0
for (i in 0..0) {
    sum = sum + 1
}
expectEq(sum, 0, "empty range 0..0")

// --- Section: for with empty exclusive range (start > end) ---
sum = 0
for (i in 5..3) {
    sum = sum + 1
}
expectEq(sum, 0, "empty range 5..3")

// --- Section: for with single element inclusive range ---
sum = 0
for (i in 5..=5) {
    sum = sum + i
}
expectEq(sum, 5, "single element range 5..=5")

// --- Section: for with single element exclusive range ---
sum = 0
for (i in 0..1) {
    sum = sum + i
}
expectEq(sum, 0, "single element 0..1")

// --- Section: nested break ---
var result = 0
for (i in 0..=10) {
    for (j in 0..=10) {
        if (j == 3) {
            break
        }
    }
    result = result + 1
}
expectEq(result, 11, "inner break does not affect outer loop")

// --- Section: continue in while loop ---
var odds = 0
var wi = 0
while (wi < 10) {
    wi = wi + 1
    if (wi % 2 == 0) {
        continue
    }
    odds = odds + 1
}
expectEq(odds, 5, "continue in while loop skips evens")

// --- Section: break immediately in for loop ---
var breakCount = 0
for (i in 0..100) {
    break
    breakCount = breakCount + 1
}
expectEq(breakCount, 0, "break immediately exits loop")

// --- Section: continue at end of for loop ---
sum = 0
for (i in 1..=5) {
    sum = sum + i
    continue
}
expectEq(sum, 15, "continue at end of loop body")

// --- Section: for-in array with single element ---
let single = [42]
var arrSum = 0
for (x in single) {
    arrSum = arrSum + x
}
expectEq(arrSum, 42, "for-in single element array")

// --- Section: for-in empty array ---
let empty: Array<Int64> = []
var emptySum = 0
for (x in empty) {
    emptySum = emptySum + x
}
expectEq(emptySum, 0, "for-in empty array")

// --- Section: range with step larger than range ---
sum = 0
for (i in 0..=2:10) {
    sum = sum + i
}
expectEq(sum, 0, "step larger than range inclusive: only i=0")

// --- Section: for loop variable does not leak ---
for (loopVar in 0..3) {
    // loopVar scoped to loop
}
// loopVar should not be accessible outside

// --- Section: deeply nested loops ---
var deepSum = 0
for (a in 1..=2) {
    for (b in 1..=2) {
        for (c in 1..=2) {
            deepSum = deepSum + a * b * c
        }
    }
}
expectEq(deepSum, 27, "deeply nested 3-level loops")

// --- Section: while with compound condition ---
var x = 0
var y = 10
while (x < 5 && y > 5) {
    x = x + 1
    y = y - 1
}
expectEq(x, 5, "while compound condition x")
expectEq(y, 5, "while compound condition y")

if (!__test_failed) {
    println("PASS: 55_loop_boundary")
}
