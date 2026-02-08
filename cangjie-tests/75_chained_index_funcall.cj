dofile("cangjie-tests/_testing.cj")

// Test: Chained indexing on class fields with function call keys
// Validates the compiler fix for register clobbering when indexing
// class fields with nested function call expressions as keys.

// --- Section: Double indexing with function call key ---

class Matrix {
    let data = [[10, 20, 30], [40, 50, 60], [70, 80, 90]]

    func getWithFunc(r: Int64): Int64 {
        return data[r][Int64(1)]
    }

    func getWithLiteral(r: Int64): Int64 {
        return data[r][1]
    }

    func getWithVar(r: Int64): Int64 {
        let c = Int64(1)
        return data[r][c]
    }
}

let m = Matrix()
expectEq(m.getWithFunc(0), 20, "chained index func key row 0")
expectEq(m.getWithFunc(1), 50, "chained index func key row 1")
expectEq(m.getWithFunc(2), 80, "chained index func key row 2")
expectEq(m.getWithLiteral(0), 20, "chained index literal key")
expectEq(m.getWithVar(0), 20, "chained index var key")

// --- Section: Chained indexing with complex function call key ---

class Table2D {
    let grid = Array(3, {i: Int64 => Array(100, {j: Int64 => i * 100 + j})})

    func lookup(row: Int64, text: String): Int64 {
        return grid[row][Rune(text[0])]
    }

    func lookupChained(row: Int64, text: String, idx: Int64): Int64 {
        return grid[row][Rune(text[idx])]
    }
}

let t = Table2D()
// 'A' = 65, so grid[0][65] = 0*100+65 = 65
expectEq(t.lookup(0, "ABC"), 65, "lookup A code point")
// 'Z' = 90, so grid[1][90] = 1*100+90 = 190
expectEq(t.lookup(1, "Z"), 190, "lookup Z code point")
// 'a' = 97, so grid[2][97] = 2*100+97 = 297
expectEq(t.lookupChained(2, "abc", 0), 297, "chained lookup a")
// 'c' = 99
expectEq(t.lookupChained(2, "abc", 2), 299, "chained lookup c")

// --- Section: Triple chaining on class field ---

class Deep {
    let cube = Array(3, {i: Int64 => Array(3, {j: Int64 => Array(3, {k: Int64 => i * 9 + j * 3 + k})})})

    func get(a: Int64, b: Int64, c: Int64): Int64 {
        return cube[a][b][c]
    }

    func getWithConversion(a: Int64): Int64 {
        return cube[a][Int64(1)][Int64(2)]
    }
}

let d = Deep()
expectEq(d.get(0, 0, 0), 0, "cube[0][0][0]")
expectEq(d.get(1, 1, 1), 13, "cube[1][1][1]")
expectEq(d.get(2, 2, 2), 26, "cube[2][2][2]")
expectEq(d.getWithConversion(0), 5, "cube with Int64 keys")
expectEq(d.getWithConversion(1), 14, "cube with Int64 keys row 1")

// --- Section: Comparison in while loop with chained access ---

class StateTable {
    let tbl = Array(2, {i: Int64 => Array(128, 0)})
    init() {
        tbl[0][65] = 1  // 'A'
        tbl[0][66] = 2  // 'B'
        tbl[1][65] = 3
        tbl[1][66] = 0
    }

    func trace(text: String): Int64 {
        var s = 0
        var i = 0
        while (i < text.size && tbl[s][Rune(text[i])] != 0) {
            s = tbl[s][Rune(text[i])]
            i = i + 1
        }
        return s
    }
}

let st = StateTable()
expectEq(st.trace("A"), 1, "trace A")
expectEq(st.trace("AB"), 1, "trace AB stops at s=1")
expectEq(st.trace(""), 0, "trace empty")
expectEq(st.trace("C"), 0, "trace C unknown char")

if (!__test_failed) {
    println("PASS: 75_chained_index_funcall")
}
