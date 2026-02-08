dofile("cangjie-tests/_testing.cj")

// Diagnosis: String UTF-8 errors and boundary conditions

// --- Section: Out of range index ---
expectRuntimeError("utf8 index out of range",
    'let s = "你好"; let _ = s[5]',
    "out of range")

expectRuntimeError("negative index",
    'let s = "hello"; let _ = s[-1]',
    "out of range")

expectRuntimeError("index on empty string",
    'let s = ""; let _ = s[0]',
    "out of range")

// --- Section: String immutability ---
expectRuntimeError("string immutable assign",
    'let s = "hello"; s[0] = "H"',
    "immutable")

// --- Section: Method on empty string ---
expectNoError("empty contains",
    'let _ = "".contains("x")')

expectNoError("empty split",
    'let _ = "".split(",")')

expectNoError("empty trim",
    'let _ = "".trim()')

expectNoError("empty toArray",
    'let _ = "".toArray()')

expectNoError("empty toRuneArray",
    'let _ = "".toRuneArray()')

// --- Section: Edge case slicing ---
expectNoError("empty slice",
    'let _ = "hello"[2..2]')

expectNoError("full inclusive slice",
    'let _ = "你好"[0..=1]')

if (!__test_failed) {
    println("PASS: diagnosis/11_string_utf8_errors")
}
