dofile("cangjie-tests/_testing.cj")

// Test: Types and operations

// -- Section: integer arithmetic --
let a: Int64 = 10
let b: Int64 = 3
expectEq(a + b, 13, "a + b")
expectEq(a - b, 7, "a - b")
expectEq(a * b, 30, "a * b")
expectEq(a % b, 1, "a % b")

// -- Section: float arithmetic --
let pi: Float64 = 3.14159
let r: Float64 = 5.0
let area = pi * r * r
expectEq(area, 78.53975, "float area")

// -- Section: boolean operations --
let t: Bool = true
let f: Bool = false
expectFalse(t && f, "t && f")
expectTrue(t || f, "t || f")
expectFalse(!t, "!t")

// -- Section: string operations --
let s1: String = "Hello"
let s2: String = "World"
let s3 = s1 + ", " + s2 + "!"
expectEq(s3, "Hello, World!", "string concat")

// -- Section: comparison operators --
expectTrue(10 == 10, "equality")
expectTrue(10 != 20, "inequality")
expectTrue(10 < 20, "less than")
expectFalse(10 > 20, "greater than")
expectTrue(10 <= 10, "less or equal")
expectFalse(10 >= 20, "greater or equal")

// -- Section: type conversions --
let n = tostring(42)
expectEq(n, "42", "tostring(42)")
let m = tonumber("123")
expectEq(m, 123, "tonumber('123')")

// -- Section: array access --
let arr: Array<Int64> = [1, 2, 3, 4, 5]
expectEq(arr[0], 1, "arr[0]")
expectEq(arr[1], 2, "arr[1]")
expectEq(arr.size, 5, "arr.size")

// -- Section: Rune type --
let ch: Rune = r'X'
expectEq(ch, r'X', "Rune ch")

if (!__test_failed) {
    println("PASS: 04_types_operations")
}
