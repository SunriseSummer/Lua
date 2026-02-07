dofile("cangjie-tests/_testing.cj")

// Test: Array initialization patterns
// Validates multi-dimensional arrays, Array(size, value), Array(size, lambda), and string arrays

// --- Multi-dimensional array ---
let matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
expectEq(matrix[0][0], 1, "matrix[0][0]")
expectEq(matrix[1][2], 6, "matrix[1][2]")
expectEq(matrix[2][1], 8, "matrix[2][1]")
expectEq(matrix.size, 3, "matrix.size")
expectEq(matrix[0].size, 3, "matrix[0].size")

// --- Array initialization with value ---
let zeros = Array<Int64>(5, 0)
expectEq(zeros[0], 0, "zeros[0]")
expectEq(zeros[4], 0, "zeros[4]")
expectEq(zeros.size, 5, "zeros.size")

// --- Array initialization with function ---
let squares = Array<Int64>(4, { i: Int64 => i * i })
expectEq(squares[0], 0, "squares[0]")
expectEq(squares[1], 1, "squares[1]")
expectEq(squares[2], 4, "squares[2]")
expectEq(squares[3], 9, "squares[3]")
expectEq(squares.size, 4, "squares.size")

// --- Multi-dimensional via Array init ---
let grid = Array<Array<Int64>>(3, { i: Int64 => Array<Int64>(3, { j: Int64 => i * 3 + j }) })
expectEq(grid[0][0], 0, "grid[0][0]")
expectEq(grid[1][1], 4, "grid[1][1]")
expectEq(grid[2][2], 8, "grid[2][2]")
expectEq(grid.size, 3, "grid.size")

// --- Array with string init ---
let names = Array<String>(3, "default")
expectEq(names[0], "default", "names[0]")
expectEq(names[2], "default", "names[2]")

if (!__test_failed) {
    println("PASS: 23_array_init")
}
