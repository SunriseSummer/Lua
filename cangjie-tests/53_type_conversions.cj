dofile("cangjie-tests/_testing.cj")

// Test: Type conversion functions

// -- Section: Int64() conversions --

// Char (Rune) to Unicode code point
let a = Int64('乐')
expectEq(a, 0x4E50, "Int64('乐') == 0x4E50")

let a2 = Int64('A')
expectEq(a2, 65, "Int64('A') == 65")

// Note: Int64('0') returns 0 (parsed as number, not code point 48)
// because '0' and "0" are identical at runtime
let a3 = Int64('0')
expectEq(a3, 0, "Int64('0') == 0")

// String to integer
let c = Int64("1234567")
expectEq(c, 1234567, "Int64(\"1234567\")")

let c2 = Int64("0")
expectEq(c2, 0, "Int64(\"0\")")

let c3 = Int64("-42")
expectEq(c3, -42, "Int64(\"-42\")")

// Float to integer (truncation)
let e = Int64(3.14)
expectEq(e, 3, "Int64(3.14) == 3")

let e2 = Int64(3.99)
expectEq(e2, 3, "Int64(3.99) == 3")

let e3 = Int64(-2.7)
expectEq(e3, -2, "Int64(-2.7) == -2")

let e4 = Int64(0.0)
expectEq(e4, 0, "Int64(0.0) == 0")

// Integer identity
let e5 = Int64(42)
expectEq(e5, 42, "Int64(42) == 42")

// -- Section: Float64() conversions --

// String to float
let b = Float64("3.14")
expectEq(b, 3.14, "Float64(\"3.14\")")

let b2 = Float64("0.0")
expectEq(b2, 0.0, "Float64(\"0.0\")")

let b3 = Float64("-1.5")
expectEq(b3, -1.5, "Float64(\"-1.5\")")

// Integer to float
let f = Float64(42)
expectEq(f, 42.0, "Float64(42) == 42.0")

let f2 = Float64(0)
expectEq(f2, 0.0, "Float64(0) == 0.0")

let f3 = Float64(-10)
expectEq(f3, -10.0, "Float64(-10) == -10.0")

// Float identity
let f4 = Float64(3.14)
expectEq(f4, 3.14, "Float64(3.14) == 3.14")

// -- Section: String() conversions --

// Integer to string
let g = String(65)
expectEq(g, "65", "String(65) == \"65\"")

let g2 = String(0)
expectEq(g2, "0", "String(0) == \"0\"")

let g3 = String(-42)
expectEq(g3, "-42", "String(-42) == \"-42\"")

// Float to string
let h = String(3.14)
expectEq(h, "3.14", "String(3.14)")

// Boolean to string
let i1 = String(true)
expectEq(i1, "true", "String(true)")

let i2 = String(false)
expectEq(i2, "false", "String(false)")

// String identity
let i3 = String("hello")
expectEq(i3, "hello", "String(\"hello\")")

// -- Section: Bool() conversions --

let d1 = Bool("true")
expectTrue(d1, "Bool(\"true\")")

let d2 = Bool("false")
expectFalse(d2, "Bool(\"false\")")

// Bool identity
let d3 = Bool(true)
expectTrue(d3, "Bool(true)")

let d4 = Bool(false)
expectFalse(d4, "Bool(false)")

// -- Section: Rune() conversions --

let j = Rune(0x4E50)
expectEq(j, "乐", "Rune(0x4E50)")

let j2 = Rune(65)
expectEq(j2, "A", "Rune(65)")

let j3 = Rune(0x1F600)
expectEq(j3, "😀", "Rune(0x1F600) emoji")

// -- Section: round-trip conversions --

// Int64 -> String -> Int64
let rt1 = 42
let rt2 = String(rt1)
expectEq(rt2, "42", "Int64->String")
let rt2b = Int64(rt2)
expectEq(rt2b, 42, "String->Int64 round-trip")

// Rune -> Int64 -> Rune
let rt3 = Int64('乐')
let rt4 = Rune(rt3)
expectEq(rt4, "乐", "Rune->Int64->Rune round-trip")

// Float64 -> String -> Float64
let rt5 = Float64("3.14")
let rt6 = String(rt5)
expectEq(rt6, "3.14", "Float64->String round-trip")

if (!__test_failed) {
    println("PASS: 53_type_conversions")
}
