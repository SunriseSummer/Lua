dofile("cangjie-tests/_testing.cj")

// Test: Array/string range slicing with computed start/end expressions
// This tests a bug fix where expressions like arr[n - m..n] would fail
// because the VRELOC result of n - m was clobbered during register
// rearrangement for the __cangjie_array_slice call.

// --- Section: Array range with variable arithmetic ---
var n = 10
let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
let r1 = arr[n - 3..n]
expectEq(r1[0], 7, "arr[n-3..n][0] with var n")
expectEq(r1[1], 8, "arr[n-3..n][1] with var n")
expectEq(r1[2], 9, "arr[n-3..n][2] with var n")

// --- Section: Array range with two variable expressions ---
var start = 2
var end = 5
let r2 = arr[start..end]
expectEq(r2[0], 2, "arr[start..end][0]")
expectEq(r2[2], 4, "arr[start..end][2]")

// --- Section: Array range with computed end ---
let r3 = arr[0..n - 7]
expectEq(r3[0], 0, "arr[0..n-7][0]")
expectEq(r3[2], 2, "arr[0..n-7][2]")

// --- Section: Array range with both computed ---
let r4 = arr[n - 8..n - 3]
expectEq(r4[0], 2, "arr[n-8..n-3][0]")
expectEq(r4[4], 6, "arr[n-8..n-3][4]")

// --- Section: Inclusive range with expression ---
let r5 = arr[n - 3..=n - 1]
expectEq(r5[0], 7, "arr[n-3..=n-1][0]")
expectEq(r5[2], 9, "arr[n-3..=n-1][2]")

// --- Section: String slicing with expression ---
let s = "hello world"
var sn = s.size
let r6 = s[sn - 5..sn]
expectEq(r6, "world", "s[sn-5..sn]")

// --- Section: String slicing with .size directly ---
let r7 = s[0..5]
expectEq(r7, "hello", "s[0..5]")

// --- Section: Multi-dim array slicing with expression ---
struct Wrapper {
    var data: Array<Array<Int64>>
    init() {
        this.data = [[10, 20, 30], [40, 50, 60]]
    }
}
let w = Wrapper()
let row = w.data[0][1..3]
expectEq(row[0], 20, "struct.data[0][1..3][0]")
expectEq(row[1], 30, "struct.data[0][1..3][1]")

// --- Section: Range assignment with expression ---
var target = [0, 0, 0, 0, 0]
var idx = 1
target[idx..idx + 3] = [10, 20, 30]
expectEq(target[1], 10, "range assign with var idx [1]")
expectEq(target[2], 20, "range assign with var idx [2]")
expectEq(target[3], 30, "range assign with var idx [3]")
expectEq(target[0], 0, "range assign [0] unchanged")
expectEq(target[4], 0, "range assign [4] unchanged")

if (!__test_failed) {
    println("PASS: 67_range_expr_fix")
}
