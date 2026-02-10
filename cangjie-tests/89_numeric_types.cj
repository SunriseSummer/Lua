dofile("cangjie-tests/_testing.cj")

// Test: Numeric literal types and mixed arithmetic

// -- Section: literal typing --
let i = 42
expectEq(type(i), "Int64", "default integer literal is Int64")

let i2 = 42i64
expectEq(type(i2), "Int64", "i64 suffix literal is Int64")

let u = 42u64
expectEq(type(u), "UInt64", "u64 suffix literal is UInt64")

let f = 3.14
expectEq(type(f), "Float64", "dot literal is Float64")

let f2 = 3.
expectEq(type(f2), "Float64", "trailing dot literal is Float64")

let f3 = 8f64
expectEq(type(f3), "Float64", "f64 suffix literal is Float64")

let f4 = 3e2f64
expectEq(f4, 300.0, "f64 suffix with exponent")

// -- Section: explicit conversions --
let cu = UInt64("123")
expectEq(type(cu), "UInt64", "UInt64 from string")
expectEq(cu, 123u64, "UInt64 value")

let ci = Int64(123u64)
expectEq(type(ci), "Int64", "Int64 from UInt64")
expectEq(ci, 123, "Int64 from UInt64 value")

let cf = Float64(5u64)
expectEq(type(cf), "Float64", "Float64 from UInt64")
expectEq(cf, 5.0, "Float64 from UInt64 value")

let cu2 = UInt64(3.9)
expectEq(cu2, 3u64, "UInt64 from float truncation")

let cu3 = UInt64(true)
expectEq(cu3, 1u64, "UInt64 from bool")

// -- Section: mixed arithmetic --
let mixed1 = 5 + 6u64
expectEq(type(mixed1), "Int64", "Int64 + UInt64 -> Int64")
expectEq(mixed1, 11, "Int64 + UInt64 value")

let mixed2 = 5u64 + 6u64
expectEq(type(mixed2), "UInt64", "UInt64 + UInt64 -> UInt64")
expectEq(mixed2, 11u64, "UInt64 + UInt64 value")

let mixed3 = 5u64 + 2.5
expectEq(type(mixed3), "Float64", "UInt64 + Float64 -> Float64")
expectEq(mixed3, 7.5, "UInt64 + Float64 value")

let mixed4 = 5 + 2.5
expectEq(type(mixed4), "Float64", "Int64 + Float64 -> Float64")
expectEq(mixed4, 7.5, "Int64 + Float64 value")

if (!__test_failed) {
    println("PASS: 89_numeric_types")
}
