dofile("cangjie-tests/_testing.cj")

// Test: Chained array indexing with function calls as index
// Validates fix for register collision when arr[x][func()] is used

// --- Section: Basic chained indexing with function call ---
let arr2d = Array(5, {i: Int64 => Array(10, 0)})
arr2d[0][5] = 42
arr2d[1][3] = 99
arr2d[2][7] = -1
arr2d[3][0] = 100
arr2d[4][9] = 77

func getIdx(n: Int64): Int64 { return n }

// Simple chained access with function call
expectEq(arr2d[0][getIdx(5)], 42, "arr2d[0][getIdx(5)]")
expectEq(arr2d[1][getIdx(3)], 99, "arr2d[1][getIdx(3)]")
expectEq(arr2d[2][getIdx(7)], -1, "arr2d[2][getIdx(7)]")

// Variable first index + function call second index
var s = 0
expectEq(arr2d[s][getIdx(5)], 42, "arr2d[s][getIdx(5)] s=0")
s = 3
expectEq(arr2d[s][getIdx(0)], 100, "arr2d[s][getIdx(0)] s=3")

// --- Section: Nested function calls in index ---
func double(n: Int64): Int64 { return n * 2 }

arr2d[0][8] = 88
expectEq(arr2d[0][double(4)], 88, "arr2d[0][double(4)]")

// --- Section: Int64() conversion as index ---
let states = Array(3, {i: Int64 => Array(128, 0)})
states[0][49] = 5  // '1' = 49
states[0][65] = 10 // 'A' = 65
states[1][32] = 20 // ' ' = 32

let text = "1A "
expectEq(states[0][Int64(text[0])], 5, "states[0][Int64('1')]")
expectEq(states[0][Int64(text[1])], 10, "states[0][Int64('A')]")

// Variable row + Int64 as column
var row = 0
expectEq(states[row][Int64(text[0])], 5, "states[row][Int64(text[0])]")
row = 1
expectEq(states[row][Int64(text[2])], 20, "states[row][Int64(' ')]")

// --- Section: Inside function context ---
func testInFunc() {
    let m = Array(3, {i: Int64 => Array(5, 0)})
    m[0][2] = 7
    m[1][4] = 8
    m[2][0] = 9

    var r = 0
    expectEq(m[r][getIdx(2)], 7, "inside func: m[r][getIdx(2)]")
    r = 1
    expectEq(m[r][getIdx(4)], 8, "inside func: m[r][getIdx(4)]")
    r = 2
    expectEq(m[r][getIdx(0)], 9, "inside func: m[r][getIdx(0)]")
}
testInFunc()

// --- Section: Inside class method ---
class Matrix {
    let data = Array(3, {i: Int64 => Array(3, 0)})
    init() {
        data[0][0] = 1
        data[1][1] = 2
        data[2][2] = 3
    }
    func get(r: Int64, c: Int64): Int64 {
        return data[r][c]
    }
    func getWithFunc(r: Int64): Int64 {
        return data[r][getIdx(r)]
    }
}

let mat = Matrix()
expectEq(mat.get(0, 0), 1, "Matrix.get(0,0)")
expectEq(mat.get(1, 1), 2, "Matrix.get(1,1)")
expectEq(mat.get(2, 2), 3, "Matrix.get(2,2)")
expectEq(mat.getWithFunc(0), 1, "Matrix.getWithFunc(0)")
expectEq(mat.getWithFunc(1), 2, "Matrix.getWithFunc(1)")
expectEq(mat.getWithFunc(2), 3, "Matrix.getWithFunc(2)")

// --- Section: Chained indexing in while loop condition ---
func testWhileLoop() {
    let grid = Array(2, {i: Int64 => Array(5, 0)})
    grid[0][0..5] = [1, 1, 1, 0, 0]
    grid[1][0..5] = [0, 0, 1, 1, 0]

    var r = 0
    var c = 0
    var count = 0
    // Count nonzero entries using chained index in while condition
    while (r < 2) {
        c = 0
        while (c < 5) {
            if (grid[r][c] != 0) {
                count = count + 1
            }
            c = c + 1
        }
        r = r + 1
    }
    expectEq(count, 5, "while loop with chained index")
}
testWhileLoop()

// --- Section: Chained indexing with reassignment ---
func testReassign() {
    let t = Array(3, {i: Int64 => Array(10, 0)})
    t[0][1] = 2
    t[2][5] = 7

    var s = 0
    let v1 = t[s][1]   // should be 2
    s = t[s][1]         // s = 2
    let v2 = t[s][5]    // t[2][5] = 7
    expectEq(v1, 2, "before reassign")
    expectEq(s, 2, "after reassign s")
    expectEq(v2, 7, "after reassign access")
}
testReassign()

if (!__test_failed) {
    println("PASS: 72_chained_index_funcall")
}
