dofile("cangjie-tests/_testing.cj")

// Test: Array and range edge cases

// --- Empty array ---
let empty: Array<Int64> = []
expectEq(empty.size, 0, "empty array size")

// --- Single element array ---
let single = [42]
expectEq(single.size, 1, "single element size")
expectEq(single[0], 42, "single element access")

// --- Array with mixed-type values (dynamic) ---
let mixed = [1, "hello", true, nil]
expectEq(mixed[0], 1, "mixed[0]")
expectEq(mixed[1], "hello", "mixed[1]")
expectEq(mixed[2], true, "mixed[2]")
expectNil(mixed[3], "mixed[3]")

// --- Array mutation ---
var arr = [10, 20, 30, 40, 50]
arr[0] = 100
expectEq(arr[0], 100, "mutation [0]")
arr[4] = 500
expectEq(arr[4], 500, "mutation [4]")

// --- Array size after init ---
let arr2 = Array<Int64>(5, 0)
expectEq(arr2.size, 5, "Array(5,0) size")
expectEq(arr2[0], 0, "Array(5,0)[0]")
expectEq(arr2[4], 0, "Array(5,0)[4]")

// --- Array with lambda init ---
let arr3 = Array<Int64>(5, { i => i * 10 })
expectEq(arr3[0], 0, "Array lambda [0]")
expectEq(arr3[1], 10, "Array lambda [1]")
expectEq(arr3[4], 40, "Array lambda [4]")

// --- Range: exclusive from 0 ---
let r1 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
let sub1 = r1[0..3]
expectEq(sub1.size, 3, "range [0..3] size")
expectEq(sub1[0], 0, "range [0..3][0]")
expectEq(sub1[2], 2, "range [0..3][2]")

// --- Range: inclusive ---
let sub2 = r1[0..=2]
expectEq(sub2.size, 3, "range [0..=2] size")
expectEq(sub2[2], 2, "range [0..=2][2]")

// --- Range: end of array ---
let sub3 = r1[7..10]
expectEq(sub3.size, 3, "range [7..10] size")
expectEq(sub3[0], 7, "range [7..10][0]")
expectEq(sub3[2], 9, "range [7..10][2]")

// --- Range: single element ---
let sub4 = r1[5..=5]
expectEq(sub4.size, 1, "range [5..=5] size")
expectEq(sub4[0], 5, "range [5..=5][0]")

// --- Range assignment ---
var arr4 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
arr4[3..6] = [10, 20, 30]
expectEq(arr4[2], 0, "range assign boundary low")
expectEq(arr4[3], 10, "range assign [3]")
expectEq(arr4[4], 20, "range assign [4]")
expectEq(arr4[5], 30, "range assign [5]")
expectEq(arr4[6], 0, "range assign boundary high")

// --- for-in iteration over array ---
let items = [10, 20, 30]
var sum = 0
for (item in items) {
    sum += item
}
expectEq(sum, 60, "for-in sum")

// --- for-in with index range ---
var sum2 = 0
for (i in 0..items.size) {
    sum2 += items[i]
}
expectEq(sum2, 60, "for index sum")

// --- Nested arrays ---
let matrix = [[1, 2], [3, 4], [5, 6]]
expectEq(matrix[0][0], 1, "matrix[0][0]")
expectEq(matrix[1][1], 4, "matrix[1][1]")
expectEq(matrix[2][0], 5, "matrix[2][0]")

// --- for loop with step ---
var evens = 0
for (i in 0..=10:2) {
    evens += i
}
expectEq(evens, 30, "step range evens")

if (!__test_failed) {
    println("PASS: 45_array_range_edge_cases")
}
