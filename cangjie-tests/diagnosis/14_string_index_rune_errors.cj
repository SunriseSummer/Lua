dofile("cangjie-tests/_testing.cj")

// Diagnosis: String indexing, String(bytes), and for-in error cases

// --- Section: Out of range index errors ---
expectRuntimeError("negative string index",
    'let s = "hello"; let _ = s[-1]',
    "out of range")

expectRuntimeError("index past end",
    'let s = "hello"; let _ = s[5]',
    "out of range")

expectRuntimeError("index on empty string",
    'let s = ""; let _ = s[0]',
    "out of range")

// --- Section: CJK out of range ---
expectRuntimeError("CJK index past end",
    'let s = "你好"; let _ = s[2]',
    "out of range")

// --- Section: String(bytes) with invalid byte values ---
expectRuntimeError("byte value > 255",
    'let t = {}; t[0] = 256; t.size = 1; t.__n = 1; let _ = String(t)',
    "byte value")

expectRuntimeError("byte value < 0",
    'let t = {}; t[0] = -1; t.size = 1; t.__n = 1; let _ = String(t)',
    "byte value")

// --- Section: Rune from multi-char string still errors ---
expectRuntimeError("Rune from multi-char string",
    'let _ = Rune("ab")',
    "single-character")

expectRuntimeError("Rune from empty string",
    'let _ = Rune("")',
    "empty string")

// --- Section: String immutability still enforced ---
expectRuntimeError("string assignment",
    'let s = "hello"; s[0] = r\'x\'',
    "immutable")

if (!__test_failed) {
    println("PASS: diagnosis/14_string_index_rune_errors")
}
