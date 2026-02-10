dofile("cangjie-tests/_testing.cj")

// Test: Int64/Float64 literal and arithmetic behavior

// --- Section: literal types ---
expectType(42, "Int64", "Int64 literal type")
expectType(3.0, "Float64", "Float64 literal type")
expectType(3., "Float64", "Float64 literal with trailing dot")

// --- Section: arithmetic type preservation ---
let intSum = 1 + 2
let floatSum = 1.0 + 2.0
let mixedSum = 1 + 2.0
expectType(intSum, "Int64", "Int64 + Int64 -> Int64")
expectType(floatSum, "Float64", "Float64 + Float64 -> Float64")
expectType(mixedSum, "Float64", "Int64 + Float64 -> Float64")

// --- Section: division rules ---
let intDiv = 7 / 2
let floatDiv = 7 / 2.0
expectEq(intDiv, 3, "Int64 / Int64 truncates")
expectType(intDiv, "Int64", "Int64 / Int64 -> Int64")
expectEq(floatDiv, 3.5, "Int64 / Float64 -> Float64")
expectType(floatDiv, "Float64", "Int64 / Float64 -> Float64")

// --- Section: power rules ---
let intPow = 2 ** 3
let floatPow = 2 ** 3.0
expectEq(intPow, 8, "Int64 ** Int64")
expectType(intPow, "Int64", "Int64 ** Int64 -> Int64")
expectEq(floatPow, 8.0, "Int64 ** Float64")
expectType(floatPow, "Float64", "Int64 ** Float64 -> Float64")

// --- Section: explicit conversions ---
expectEq(Float64(3), 3.0, "Float64(Int64)")
expectEq(Int64(3.9), 3, "Int64(Float64) truncates")
expectEq(Float64("3"), 3.0, "Float64 from numeric string")
expectEq(Int64("3.14"), 3, "Int64 from numeric string")

if (!__test_failed) {
    println("PASS: 89_number_types")
}
