dofile("cangjie-tests/_testing.cj")

// Test: Variable declarations (let and var)

// -- Section: let declarations with type annotations --
let a: Int64 = 10
let b: Float64 = 3.14
let c: String = "hello"
let d: Bool = true
let e: Bool = false

expectEq(a, 10, "let Int64 a")
expectEq(b, 3.14, "let Float64 b")
expectEq(c, "hello", "let String c")
expectTrue(d, "let Bool d")
expectFalse(e, "let Bool e")

// -- Section: Rune (character) type --
let ch: Rune = r'A'
expectEq(ch, 65, "Rune ch")

// -- Section: var declarations (mutable) --
var x: Int64 = 1
expectEq(x, 1, "var x initial")
x = 2
expectEq(x, 2, "var x after assignment")
x = x + 10
expectEq(x, 12, "var x after x+10")

// -- Section: Array type (0-based indexing) --
let arr: Array<Int64> = [1, 2, 3, 4, 5]
expectEq(arr[0], 1, "arr[0]")
expectEq(arr[1], 2, "arr[1]")
expectEq(arr.size, 5, "arr.size")

// -- Section: type inference --
let pi = 3.14159
expectEq(pi, 3.14159, "type inference pi")

if (!__test_failed) {
    println("PASS: 01_variables")
}
