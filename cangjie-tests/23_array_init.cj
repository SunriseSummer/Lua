// Multi-dimensional array
let matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
println(matrix[0][0])    // 1
println(matrix[1][2])    // 6
println(matrix[2][1])    // 8
println(matrix.size)     // 3
println(matrix[0].size)  // 3

// Array initialization with value
let zeros = Array<Int64>(5, 0)
println(zeros[0])        // 0
println(zeros[4])        // 0
println(zeros.size)      // 5

// Array initialization with function
let squares = Array<Int64>(4, { i: Int64 => i * i })
println(squares[0])      // 0
println(squares[1])      // 1
println(squares[2])      // 4
println(squares[3])      // 9
println(squares.size)    // 4

// Multi-dimensional via Array init
let grid = Array<Array<Int64>>(3, { i: Int64 => Array<Int64>(3, { j: Int64 => i * 3 + j }) })
println(grid[0][0])      // 0
println(grid[1][1])      // 4
println(grid[2][2])      // 8
println(grid.size)       // 3

// Array with string init
let names = Array<String>(3, "default")
println(names[0])        // default
println(names[2])        // default

println("PASS: 23_array_init")
