dofile("cangjie-tests/_testing.cj")

// Test: Int64/Float64 native type tags and extension separation

// --- Section: literal type tags ---
expectEq(type(1), "Int64", "type(1) == Int64")
expectEq(type(1.25), "Float64", "type(1.25) == Float64")

// --- Section: conversion preserves type tags ---
let i = Int64(3.14)
let f = Float64(3)
expectEq(type(i), "Int64", "Int64(3.14) yields Int64")
expectEq(type(f), "Float64", "Float64(3) yields Float64")

// --- Section: mixed arithmetic promotes to Float64 ---
let sumInt = 1 + 2
let sumFloat = 1 + 2.5
expectEq(type(sumInt), "Int64", "Int64 + Int64 yields Int64")
expectEq(type(sumFloat), "Float64", "Int64 + Float64 yields Float64")

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
