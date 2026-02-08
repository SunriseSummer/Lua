dofile("cangjie-tests/_testing.cj")

// Test: Range step and for-in edge cases

// --- Section: Exclusive range with step ---
var sum = 0
for (i in 0..10:2) {
    sum = sum + i
}
expectEq(sum, 20, "exclusive range step 2: 0+2+4+6+8=20")

sum = 0
for (i in 0..10:3) {
    sum = sum + i
}
expectEq(sum, 18, "exclusive range step 3: 0+3+6+9=18")

sum = 0
for (i in 1..10:4) {
    sum = sum + i
}
expectEq(sum, 15, "exclusive range step 4: 1+5+9=15")

// --- Section: Inclusive range with step ---
sum = 0
for (i in 0..=10:2) {
    sum = sum + i
}
expectEq(sum, 30, "inclusive range step 2: 0+2+4+6+8+10=30")

sum = 0
for (i in 0..=9:3) {
    sum = sum + i
}
expectEq(sum, 18, "inclusive range step 3: 0+3+6+9=18")

// --- Section: Range with step=1 (should be same as no step) ---
sum = 0
for (i in 0..5:1) {
    sum = sum + i
}
expectEq(sum, 10, "exclusive range step 1: 0+1+2+3+4=10")

sum = 0
for (i in 0..5) {
    sum = sum + i
}
expectEq(sum, 10, "exclusive range no step: 0+1+2+3+4=10")

// --- Section: Range with variable as endpoint ---
let n = 10
sum = 0
for (i in 0..n:3) {
    sum = sum + i
}
expectEq(sum, 18, "variable endpoint step 3: 0+3+6+9=18")

// --- Section: Range with .size ---
let arr = [10, 20, 30, 40, 50]
var collected = ""
for (i in 0..arr.size:2) {
    collected = collected + tostring(arr[i]) + ","
}
expectEq(collected, "10,30,50,", ".size endpoint step 2")

// --- Section: Range with expression as endpoint ---
let arr2 = [1, 2, 3, 4, 5, 6, 7, 8]
sum = 0
for (i in 0..arr2.size:2) {
    sum = sum + arr2[i]
}
expectEq(sum, 16, "arr.size step 2: 1+3+5+7=16")

// --- Section: Inclusive range without step ---
sum = 0
for (i in 0..=4) {
    sum = sum + i
}
expectEq(sum, 10, "inclusive range no step: 0+1+2+3+4=10")

// --- Section: Empty range ---
sum = 0
for (i in 5..5) {
    sum = sum + i
}
expectEq(sum, 0, "empty exclusive range 5..5")

// --- Section: Large step skipping all ---
sum = 0
for (i in 0..3:10) {
    sum = sum + i
}
expectEq(sum, 0, "large step skipping: 0..3:10 => only 0")

if (!__test_failed) {
    println("PASS: 50_range_step")
}
