dofile("cangjie-tests/_testing.cj")

// Diagnosis: String cacheIndex and cache-related error conditions

// --- Section: Out of range after cacheIndex ---
expectRuntimeError("cached index out of range positive",
    'let s = "你好"; s.cacheIndex(); let _ = s[5]',
    "out of range")

expectRuntimeError("cached index negative",
    'let s = "hello"; s.cacheIndex(); let _ = s[-1]',
    "out of range")

expectRuntimeError("cached index on empty string",
    'let s = ""; s.cacheIndex(); let _ = s[0]',
    "out of range")

expectRuntimeError("cached index exactly at size",
    'let s = "abc"; s.cacheIndex(); let _ = s[3]',
    "out of range")

// --- Section: Immutability preserved after cacheIndex ---
expectRuntimeError("immutable after cacheIndex",
    'let s = "hello"; s.cacheIndex(); s[0] = "H"',
    "immutable")

// --- Section: cacheIndex on various edge cases without error ---
expectNoError("cacheIndex on empty string",
    'let s = ""; s.cacheIndex()')

expectNoError("cacheIndex on single char",
    'let s = "X"; s.cacheIndex(); let _ = s[0]')

expectNoError("cacheIndex on single CJK",
    'let s = "你"; s.cacheIndex(); let _ = s[0]')

expectNoError("cacheIndex on single emoji",
    'let s = "😀"; s.cacheIndex(); let _ = s[0]')

expectNoError("double cacheIndex call",
    'let s = "hello"; s.cacheIndex(); s.cacheIndex(); let _ = s[0]')

// --- Section: Size boundary errors ---
expectRuntimeError("index at size boundary",
    'let s = "你好世界"; let _ = s[4]',
    "out of range")

expectRuntimeError("cached index at size boundary",
    'let s = "你好世界"; s.cacheIndex(); let _ = s[4]',
    "out of range")

// --- Section: Slice edge cases ---
expectNoError("empty slice after cacheIndex",
    'let s = "hello"; s.cacheIndex(); let _ = s[2..2]')

expectNoError("slice past end clamping",
    'let _ = "hi"[0..=100]')

expectNoError("slice past end with cache",
    'let s = "hi"; s.cacheIndex(); let _ = s[0..=100]')

if (!__test_failed) {
    println("PASS: diagnosis/13_string_cache_errors")
}
