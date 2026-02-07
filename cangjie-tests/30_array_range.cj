dofile("cangjie-tests/_testing.cj")

// Test: Array range expression indexing

// Basic array
let arr = [10, 20, 30, 40, 50, 60, 70]

// Exclusive range: arr[0..3] -> elements at indices 0, 1, 2
let r1 = arr[0..3]
expectEq(r1[0], 10, "arr[0..3][0]")
expectEq(r1[1], 20, "arr[0..3][1]")
expectEq(r1[2], 30, "arr[0..3][2]")

// Inclusive range: arr[2..=4] -> elements at indices 2, 3, 4
let r2 = arr[2..=4]
expectEq(r2[0], 30, "arr[2..=4][0]")
expectEq(r2[1], 40, "arr[2..=4][1]")
expectEq(r2[2], 50, "arr[2..=4][2]")

// Range from start
let r3 = arr[0..=2]
expectEq(r3[0], 10, "arr[0..=2][0]")
expectEq(r3[1], 20, "arr[0..=2][1]")
expectEq(r3[2], 30, "arr[0..=2][2]")

// Range at end
let r4 = arr[4..7]
expectEq(r4[0], 50, "arr[4..7][0]")
expectEq(r4[1], 60, "arr[4..7][1]")
expectEq(r4[2], 70, "arr[4..7][2]")

// Single element range
let r5 = arr[3..=3]
expectEq(r5[0], 40, "arr[3..=3][0]")

// Range assignment: exclusive
var arr2 = [0, 0, 0, 0, 0]
arr2[1..3] = [100, 200]
expectEq(arr2[0], 0, "arr2[0] after range assign")
expectEq(arr2[1], 100, "arr2[1] after range assign")
expectEq(arr2[2], 200, "arr2[2] after range assign")
expectEq(arr2[3], 0, "arr2[3] after range assign")
expectEq(arr2[4], 0, "arr2[4] after range assign")

// Range assignment: inclusive
var arr3 = [0, 0, 0, 0, 0, 0]
arr3[2..=4] = [10, 20, 30]
expectEq(arr3[0], 0, "arr3[0] after range assign")
expectEq(arr3[1], 0, "arr3[1] after range assign")
expectEq(arr3[2], 10, "arr3[2] after range assign")
expectEq(arr3[3], 20, "arr3[3] after range assign")
expectEq(arr3[4], 30, "arr3[4] after range assign")
expectEq(arr3[5], 0, "arr3[5] after range assign")

// Verify sliced array has correct size
let r6 = arr[1..=5]
expectEq(r6.__n, 5, "arr[1..=5].__n")

if (!__test_failed) {
    println("PASS: 30_array_range")
}
