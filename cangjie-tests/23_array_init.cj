// Test: Array initialization patterns
// Validates multi-dimensional arrays, Array(size, value), Array(size, lambda), and string arrays

// --- Multi-dimensional array ---
let matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
if (matrix[0][0] != 1) { println("FAIL: matrix[0][0] expected 1, got ${matrix[0][0]}"); return () }
if (matrix[1][2] != 6) { println("FAIL: matrix[1][2] expected 6, got ${matrix[1][2]}"); return () }
if (matrix[2][1] != 8) { println("FAIL: matrix[2][1] expected 8, got ${matrix[2][1]}"); return () }
if (matrix.size != 3) { println("FAIL: matrix.size expected 3, got ${matrix.size}"); return () }
if (matrix[0].size != 3) { println("FAIL: matrix[0].size expected 3, got ${matrix[0].size}"); return () }

// --- Array initialization with value ---
let zeros = Array<Int64>(5, 0)
if (zeros[0] != 0) { println("FAIL: zeros[0] expected 0, got ${zeros[0]}"); return () }
if (zeros[4] != 0) { println("FAIL: zeros[4] expected 0, got ${zeros[4]}"); return () }
if (zeros.size != 5) { println("FAIL: zeros.size expected 5, got ${zeros.size}"); return () }

// --- Array initialization with function ---
let squares = Array<Int64>(4, { i: Int64 => i * i })
if (squares[0] != 0) { println("FAIL: squares[0] expected 0, got ${squares[0]}"); return () }
if (squares[1] != 1) { println("FAIL: squares[1] expected 1, got ${squares[1]}"); return () }
if (squares[2] != 4) { println("FAIL: squares[2] expected 4, got ${squares[2]}"); return () }
if (squares[3] != 9) { println("FAIL: squares[3] expected 9, got ${squares[3]}"); return () }
if (squares.size != 4) { println("FAIL: squares.size expected 4, got ${squares.size}"); return () }

// --- Multi-dimensional via Array init ---
let grid = Array<Array<Int64>>(3, { i: Int64 => Array<Int64>(3, { j: Int64 => i * 3 + j }) })
if (grid[0][0] != 0) { println("FAIL: grid[0][0] expected 0, got ${grid[0][0]}"); return () }
if (grid[1][1] != 4) { println("FAIL: grid[1][1] expected 4, got ${grid[1][1]}"); return () }
if (grid[2][2] != 8) { println("FAIL: grid[2][2] expected 8, got ${grid[2][2]}"); return () }
if (grid.size != 3) { println("FAIL: grid.size expected 3, got ${grid.size}"); return () }

// --- Array with string init ---
let names = Array<String>(3, "default")
if (names[0] != "default") { println("FAIL: names[0] expected 'default', got '${names[0]}'"); return () }
if (names[2] != "default") { println("FAIL: names[2] expected 'default', got '${names[2]}'"); return () }

println("PASS: 23_array_init")
