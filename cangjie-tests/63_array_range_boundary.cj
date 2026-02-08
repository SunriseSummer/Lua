dofile("cangjie-tests/_testing.cj")

// Test: Array and range boundary edge cases

// --- Section: Empty array ---
let empty: Array<Int64> = []
expectEq(empty.size, 0, "empty array size")

// --- Section: Single element array ---
let single = [42]
expectEq(single.size, 1, "single element size")
expectEq(single[0], 42, "single element access")

// --- Section: Array(size, value) with size 0 ---
let zeroArr = Array<Int64>(0, 0)
expectEq(zeroArr.size, 0, "Array(0, 0) size")

// --- Section: Array(size, value) with size 1 ---
let oneArr = Array<Int64>(1, 99)
expectEq(oneArr.size, 1, "Array(1, 99) size")
expectEq(oneArr[0], 99, "Array(1, 99) value")

// --- Section: Array(size, lambda) ---
let squares = Array<Int64>(5, { i: Int64 => i * i })
expectEq(squares[0], 0, "squares[0]")
expectEq(squares[1], 1, "squares[1]")
expectEq(squares[4], 16, "squares[4]")

// --- Section: Nested array access ---
let matrix = [[1, 2], [3, 4], [5, 6]]
expectEq(matrix[0][0], 1, "matrix[0][0]")
expectEq(matrix[2][1], 6, "matrix[2][1]")
expectEq(matrix.size, 3, "matrix rows")
expectEq(matrix[0].size, 2, "matrix cols")

// --- Section: Array mutation ---
var arr = [10, 20, 30]
arr[0] = 100
expectEq(arr[0], 100, "mutated arr[0]")
arr[2] = 300
expectEq(arr[2], 300, "mutated arr[2]")

// --- Section: Array slice from start ---
let src = [1, 2, 3, 4, 5]
let fromStart = src[0..3]
expectEq(fromStart[0], 1, "slice from start [0]")
expectEq(fromStart[2], 3, "slice from start [2]")

// --- Section: Array slice to end ---
let toEnd = src[3..5]
expectEq(toEnd[0], 4, "slice to end [0]")
expectEq(toEnd[1], 5, "slice to end [1]")

// --- Section: Array slice entire ---
let full = src[0..5]
expectEq(full.size, 5, "full slice size")
expectEq(full[0], 1, "full slice [0]")
expectEq(full[4], 5, "full slice [4]")

// --- Section: Array inclusive slice ---
let incl = src[1..=3]
expectEq(incl.size, 3, "inclusive slice size")
expectEq(incl[0], 2, "inclusive slice [0]")
expectEq(incl[2], 4, "inclusive slice [2]")

// --- Section: Range assignment ---
var target = [0, 0, 0, 0, 0]
target[1..3] = [10, 20]
expectEq(target[0], 0, "range assign [0] unchanged")
expectEq(target[1], 10, "range assign [1]")
expectEq(target[2], 20, "range assign [2]")
expectEq(target[3], 0, "range assign [3] unchanged")

// --- Section: Inclusive range assignment ---
var target2 = [0, 0, 0, 0, 0]
target2[0..=2] = [7, 8, 9]
expectEq(target2[0], 7, "inclusive assign [0]")
expectEq(target2[1], 8, "inclusive assign [1]")
expectEq(target2[2], 9, "inclusive assign [2]")
expectEq(target2[3], 0, "inclusive assign [3] unchanged")

// --- Section: for-in with array of strings ---
let words = ["hello", "world", "test"]
var concat = ""
for (w in words) {
    concat = concat + w + " "
}
expectEq(concat, "hello world test ", "for-in string array")

// --- Section: Nested for-in ---
let grid = [[1, 2], [3, 4]]
var gridSum = 0
for (row in grid) {
    for (val in row) {
        gridSum = gridSum + val
    }
}
expectEq(gridSum, 10, "nested for-in grid sum")

// --- Section: Array with mixed init and access ---
let mixed = [1, "two", true, 3.14]
expectEq(mixed[0], 1, "mixed array int")
expectEq(mixed[1], "two", "mixed array string")
expectEq(mixed[2], true, "mixed array bool")
expectEq(mixed[3], 3.14, "mixed array float")

if (!__test_failed) {
    println("PASS: 63_array_range_boundary")
}
