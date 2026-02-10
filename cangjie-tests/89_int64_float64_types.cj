dofile("cangjie-tests/_testing.cj")

// Test: Int64/Float64 native type tags and extension separation

// --- Section: literal type tags ---
expectType(1, "Int64", "type(1) == Int64")
expectType(1.25, "Float64", "type(1.25) == Float64")

// --- Section: conversion preserves type tags ---
let i = Int64(3.14)
let f = Float64(3)
expectType(i, "Int64", "Int64(3.14) yields Int64")
expectType(f, "Float64", "Float64(3) yields Float64")

// --- Section: mixed arithmetic promotes to Float64 ---
let sumInt = 1 + 2
let sumFloat = 1 + 2.5
expectType(sumInt, "Int64", "Int64 + Int64 yields Int64")
expectType(sumFloat, "Float64", "Int64 + Float64 yields Float64")

// --- Section: Int64 operators and edge cases ---
let add = 20 + 22
let sub = 5 - 12
let mul = 6 * 7
let mod = 17 % 5
let neg = -9
expectEq(add, 42, "Int64 add works")
expectEq(sub, -7, "Int64 sub works")
expectEq(mul, 42, "Int64 mul works")
expectEq(mod, 2, "Int64 mod works")
expectEq(neg, -9, "Int64 unary minus works")
expectType(add, "Int64", "Int64 add keeps Int64")
expectType(sub, "Int64", "Int64 sub keeps Int64")
expectType(mul, "Int64", "Int64 mul keeps Int64")
expectType(mod, "Int64", "Int64 mod keeps Int64")
expectType(neg, "Int64", "Int64 unary minus keeps Int64")

let div = 7 / 2
let powVal = 2 ** 3
expectEq(div, 3, "Int64 / Int64 yields Int64 value")
expectEq(powVal, 8, "Int64 ** Int64 yields Int64 value")
expectType(div, "Int64", "division yields Int64")
expectType(powVal, "Int64", "pow yields Int64")

let x = 12
let divExact = x / 2
let powSquare = x ** 2
expectEq(divExact, 6, "Int64 / Int64 exact division yields Int64 value")
expectEq(powSquare, 144, "Int64 ** Int64 square yields Int64 value")
expectType(divExact, "Int64", "exact division keeps Int64")
expectType(powSquare, "Int64", "square pow keeps Int64")

let powNeg = 2 ** (-1)
expectEq(powNeg, 0.5, "Int64 ** negative Int64 yields Float64 value")
expectType(powNeg, "Float64", "negative exponent yields Float64")

let band = 5 & 3
let bor = 5 | 2
let bxor = 5 ^ 1
let shl = 1 << 6
let shr = 64 >> 3
expectEq(band, 1, "bitwise and works")
expectEq(bor, 7, "bitwise or works")
expectEq(bxor, 4, "bitwise xor works")
expectEq(shl, 64, "left shift works")
expectEq(shr, 8, "right shift works")
expectType(band, "Int64", "bitwise and keeps Int64")
expectType(bor, "Int64", "bitwise or keeps Int64")
expectType(bxor, "Int64", "bitwise xor keeps Int64")
expectType(shl, "Int64", "left shift keeps Int64")
expectType(shr, "Int64", "right shift keeps Int64")

let bigShift = 1 << 60
expectEq(bigShift >> 60, 1, "large shift boundary works")
expectType(bigShift, "Int64", "large shift keeps Int64")
expectType(bigShift >> 60, "Int64", "shift result keeps Int64")

// --- Section: mixed Int64/Float64 arithmetic ---
let mixedAdd = 2 + 0.5
let mixedMul = 3 * 0.5
let mixedSub = 5.5 - 2
expectEq(mixedAdd, 2.5, "mixed add works")
expectEq(mixedMul, 1.5, "mixed mul works")
expectEq(mixedSub, 3.5, "mixed sub works")
expectType(mixedAdd, "Float64", "mixed add yields Float64")
expectType(mixedMul, "Float64", "mixed mul yields Float64")
expectType(mixedSub, "Float64", "mixed sub yields Float64")

// --- Section: math library with Int64/Float64 ---
let absInt = math.abs(-42)
let absFloat = math.abs(-3.5)
expectEq(absInt, 42, "math.abs(Int64) works")
expectEq(absFloat, 3.5, "math.abs(Float64) works")
expectType(absInt, "Int64", "math.abs(Int64) keeps Int64")
expectType(absFloat, "Float64", "math.abs(Float64) keeps Float64")

let floorVal = math.floor(3.9)
let ceilVal = math.ceil(3.1)
expectEq(floorVal, 3, "math.floor(Float64) works")
expectEq(ceilVal, 4, "math.ceil(Float64) works")
expectType(floorVal, "Int64", "math.floor returns Int64")
expectType(ceilVal, "Int64", "math.ceil returns Int64")

let sqrtVal = math.sqrt(16)
expectEq(sqrtVal, 4.0, "math.sqrt(Int64) works")
expectType(sqrtVal, "Float64", "math.sqrt returns Float64")

let maxMixed = math.max(3, 4.5, 2)
let minMixed = math.min(2.25, -1, 3)
expectEq(maxMixed, 4.5, "math.max mixed works")
expectEq(minMixed, -1, "math.min mixed works")
expectType(maxMixed, "Float64", "math.max returns Float64")
expectType(minMixed, "Int64", "math.min returns Int64")

expectEq(math.type(3), "integer", "math.type(Int64) == integer")
expectEq(math.type(3.5), "float", "math.type(Float64) == float")
expectType(math.pi, "Float64", "math.pi is Float64")

let maxInt = math.maxinteger
let minInt = math.mininteger
let hugeVal = math.huge
expectType(maxInt, "Int64", "math.maxinteger type")
expectType(minInt, "Int64", "math.mininteger type")
expectTrue(maxInt > 0 && minInt < 0, "Int64 range bounds")
expectType(hugeVal, "Float64", "math.huge type")
expectTrue(hugeVal > 1e308, "Float64 range upper bound")

let combo = (math.abs(-8) + 0.5) ** 2
expectEq(combo, 72.25, "mixed math/pow combo works")
expectType(combo, "Float64", "mixed math/pow yields Float64")

// --- Section: extend Int64/Float64 methods independently ---
extend Int64 {
    func kind(): String { return "int" }
}

extend Float64 {
    func kind(): String { return "float" }
}

expectEq(Int64(5).kind(), "int", "Int64 extension method works")
expectEq(Float64(5.5).kind(), "float", "Float64 extension method works")

if (!__test_failed) {
    println("PASS: 89_int64_float64_types")
}
