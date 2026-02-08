dofile("cangjie-tests/_testing.cj")

// Diagnosis: Chained indexing and Int64 conversion error cases

// --- Section: Int64 conversion errors ---
expectRuntimeError("Int64 empty string",
    "let x = Int64(\"\")",
    "cannot convert empty string")

expectRuntimeError("Int64 multi-char non-numeric",
    "let x = Int64(\"abc\")",
    "cannot convert")

expectRuntimeError("Int64 nil",
    "let x = Int64(nil)",
    "cannot convert")

// --- Section: Array out-of-bounds returns nil (Lua table semantics) ---
expectNoError("array negative index returns nil",
    "let a = Array(5, 0); let x = a[-1]")

expectNoError("array index too large returns nil",
    "let a = Array(5, 0); let x = a[5]")

// --- Section: String index out of bounds ---
expectRuntimeError("string negative index",
    "let s = \"hi\"; let c = s[-1]",
    "out of range")

expectRuntimeError("string index at size",
    "let s = \"hi\"; let c = s[2]",
    "out of range")

// --- Section: 2D array nil row access ---
expectRuntimeError("nil row access",
    "let a = Array(3, 0); let x = a[0][0]",
    "index")

if (!__test_failed) {
    println("PASS: diagnosis/11_index_conversion_errors")
}
