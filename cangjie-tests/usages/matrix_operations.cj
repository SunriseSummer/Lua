dofile("cangjie-tests/_testing.cj")

// Comprehensive usage: Matrix operations using interfaces, operators,
// multi-dim arrays, compound assignment, and field defaults.

interface Displayable {
    func display(): String {
        return tostring(this)
    }
}

class Matrix <: Displayable {
    var rows = 0
    var cols = 0
    var data = [[]]

    Matrix(r: Int64, c: Int64) {
        rows = r
        cols = c
        data = Array(r, { i: Int64 => Array(c, 0) })
    }

    func get(r: Int64, c: Int64): Int64 {
        return data[r][c]
    }

    func set(r: Int64, c: Int64, v: Int64) {
        data[r][c] = v
    }

    operator func +(other: Matrix): Matrix {
        let result = Matrix(rows, cols)
        for (i in 0..rows) {
            for (j in 0..cols) {
                result.set(i, j, this.get(i, j) + other.get(i, j))
            }
        }
        return result
    }

    operator func *(scalar: Int64): Matrix {
        let result = Matrix(rows, cols)
        for (i in 0..rows) {
            for (j in 0..cols) {
                result.set(i, j, this.get(i, j) * scalar)
            }
        }
        return result
    }

    func display(): String {
        return "Matrix(${rows}x${cols})"
    }
}

// Create and populate matrices
let m1 = Matrix(2, 3)
m1.set(0, 0, 1)
m1.set(0, 1, 2)
m1.set(0, 2, 3)
m1.set(1, 0, 4)
m1.set(1, 1, 5)
m1.set(1, 2, 6)

let m2 = Matrix(2, 3)
m2.set(0, 0, 10)
m2.set(0, 1, 20)
m2.set(0, 2, 30)
m2.set(1, 0, 40)
m2.set(1, 1, 50)
m2.set(1, 2, 60)

// Test matrix addition
let m3 = m1 + m2
expectEq(m3.get(0, 0), 11, "m1+m2 [0][0]")
expectEq(m3.get(0, 1), 22, "m1+m2 [0][1]")
expectEq(m3.get(0, 2), 33, "m1+m2 [0][2]")
expectEq(m3.get(1, 0), 44, "m1+m2 [1][0]")
expectEq(m3.get(1, 1), 55, "m1+m2 [1][1]")
expectEq(m3.get(1, 2), 66, "m1+m2 [1][2]")

// Test scalar multiplication
let m4 = m1 * 3
expectEq(m4.get(0, 0), 3, "m1*3 [0][0]")
expectEq(m4.get(1, 2), 18, "m1*3 [1][2]")

// Test display default method
expectEq(m1.display(), "Matrix(2x3)", "m1.display()")

// Multi-dim array range on matrix data
let row_slice = m1.data[0][1..3]
expectEq(row_slice[0], 2, "row slice [0]")
expectEq(row_slice[1], 3, "row slice [1]")

// Range assignment on matrix data
m1.data[1][0..3] = [100, 200, 300]
expectEq(m1.get(1, 0), 100, "range assign m1[1][0]")
expectEq(m1.get(1, 1), 200, "range assign m1[1][1]")
expectEq(m1.get(1, 2), 300, "range assign m1[1][2]")

if (!__test_failed) {
    println("PASS: matrix_operations")
}
