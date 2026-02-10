dofile("cangjie-tests/_testing.cj")

// Test: Int64/Float64 type conversion error diagnosis

// --- Section: Int64 conversion errors ---
expectRuntimeError("Int64 from invalid string",
    'return Int64("abc")',
    "cannot convert")

expectRuntimeError("Int64 from empty string",
    'return Int64("")',
    "cannot convert")

expectRuntimeError("Int64 from nil",
    'return Int64(nil)',
    "cannot convert")

// --- Section: Float64 conversion errors ---
expectRuntimeError("Float64 from invalid string",
    'return Float64("abc")',
    "cannot convert")

expectRuntimeError("Float64 from empty string",
    'return Float64("")',
    "cannot convert")

expectRuntimeError("Float64 from nil",
    'return Float64(nil)',
    "cannot convert")

expectRuntimeError("Float64 from boolean",
    'return Float64(true)',
    "cannot convert")

// --- Section: Division by zero ---
expectRuntimeError("int division by zero",
    'return 10 / 0',
    "divide by zero")

expectRuntimeError("int modulo by zero",
    'return 10 % 0',
    "0")

// --- Section: Negative integer power (compile-time error from constant folding) ---
expectLoadError("negative integer power literal",
    'return 2 ** (-1)',
    "negative power")

// Negative power with non-constant is a runtime error
expectRuntimeError("negative integer power runtime",
    'var e = 1; e = -e; let r = 2 ** e',
    "negative power")

if (!__test_failed) {
    println("PASS: 17_int64_float64_errors")
}
