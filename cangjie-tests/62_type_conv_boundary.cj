dofile("cangjie-tests/_testing.cj")

// Test: Type conversion boundary cases

// --- Section: Int64 conversion edge cases ---
expectEq(Int64(0.0), 0, "Int64(0.0)")
expectEq(Int64(0.9), 0, "Int64(0.9) truncates")
expectEq(Int64(-0.9), 0, "Int64(-0.9) truncates")
expectEq(Int64(1.999), 1, "Int64(1.999) truncates")
expectEq(Int64(-1.999), -1, "Int64(-1.999) truncates")
expectEq(Int64("0"), 48, "Int64(\"0\") returns code point 48")
expectEq(Int64("-42"), -42, "Int64 from negative string")
expectEq(Int64(42), 42, "Int64 identity")

// --- Section: Float64 conversion edge cases ---
expectEq(Float64(0), 0.0, "Float64(0)")
expectEq(Float64(-1), -1.0, "Float64(-1)")
expectEq(Float64("0.0"), 0.0, "Float64 from string 0.0")
expectEq(Float64("-3.14"), -3.14, "Float64 from negative string")
expectEq(Float64(3.14), 3.14, "Float64 identity")

// --- Section: String conversion edge cases ---
expectEq(String(0), "0", "String(0)")
expectEq(String(-42), "-42", "String(-42)")
expectEq(String(true), "true", "String(true)")
expectEq(String(false), "false", "String(false)")
expectEq(String("hello"), "hello", "String identity")

// --- Section: Bool conversion edge cases ---
expectEq(Bool("true"), true, "Bool from true string")
expectEq(Bool("false"), false, "Bool from false string")
expectEq(Bool(true), true, "Bool identity true")
expectEq(Bool(false), false, "Bool identity false")

// --- Section: Rune conversion edge cases ---
let r1 = Rune(65)
expectEq(Int64(r1), 65, "Rune(65) -> Int64 is 65")
let r2 = Rune(0)
expectEq(Int64(r2), 0, "Rune(0) -> Int64 is 0")
let r3 = Rune(0x10FFFF)
expectEq(Int64(r3), 0x10FFFF, "Rune(max) -> Int64")

// --- Section: Round-trip conversions ---
let original = 12345
let str = String(original)
let back = Int64(str)
expectEq(back, original, "Int64 round-trip via String")

let origFloat = 2.718
let strFloat = String(origFloat)
let backFloat = Float64(strFloat)
expectEq(backFloat, origFloat, "Float64 round-trip via String")

// --- Section: Float to Int truncation ---
expectEq(Int64(3.7), 3, "truncate 3.7 to 3")
expectEq(Int64(-3.7), -3, "truncate -3.7 to -3")
expectEq(Int64(100.0), 100, "truncate 100.0 to 100")

// --- Section: Int64 from Rune with Unicode ---
let zhong = r'\u{4e2d}'
expectEq(Int64(zhong), 0x4e2d, "Int64 from unicode rune")

// --- Section: String(Float64) precision ---
let piStr = String(3.14)
expectEq(piStr, "3.14", "String(3.14)")
let intFloatStr = String(1.0)
expectEq(intFloatStr, "1.0", "String(1.0)")

if (!__test_failed) {
    println("PASS: 62_type_conv_boundary")
}
