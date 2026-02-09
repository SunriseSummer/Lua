dofile("cangjie-tests/_testing.cj")

// Test: String cacheIndex() method and UTF-8 performance optimizations
// cacheIndex() builds an offset table for O(1) character-level indexing

// --- Section: Basic cacheIndex with ASCII ---
let ascii = "hello"
ascii.cacheIndex()
expectEq(ascii.size, 5, "cached ASCII .size")
expectEq(ascii[0], "h", "cached ASCII index 0")
expectEq(ascii[4], "o", "cached ASCII index 4")
expectEq(ascii[0..3], "hel", "cached ASCII slice 0..3")
expectEq(ascii[0..=4], "hello", "cached ASCII inclusive slice")

// --- Section: cacheIndex with CJK strings ---
let cjk = "你好世界"
cjk.cacheIndex()
expectEq(cjk.size, 4, "cached CJK .size")
expectEq(cjk[0], "你", "cached CJK index 0")
expectEq(cjk[1], "好", "cached CJK index 1")
expectEq(cjk[2], "世", "cached CJK index 2")
expectEq(cjk[3], "界", "cached CJK index 3")

// --- Section: cacheIndex with CJK slicing ---
expectEq(cjk[0..2], "你好", "cached CJK slice 0..2")
expectEq(cjk[1..3], "好世", "cached CJK slice 1..3")
expectEq(cjk[0..=3], "你好世界", "cached CJK inclusive slice full")
expectEq(cjk[2..=2], "世", "cached CJK inclusive slice single")
expectEq(cjk[2..2], "", "cached CJK empty slice")

// --- Section: cacheIndex with mixed content ---
let mixed = "Hello你好"
mixed.cacheIndex()
expectEq(mixed.size, 7, "cached mixed .size")
expectEq(mixed[0], "H", "cached mixed index 0")
expectEq(mixed[4], "o", "cached mixed index 4")
expectEq(mixed[5], "你", "cached mixed index 5")
expectEq(mixed[6], "好", "cached mixed index 6")
expectEq(mixed[0..5], "Hello", "cached mixed slice ASCII part")
expectEq(mixed[5..=6], "你好", "cached mixed slice CJK part")

// --- Section: cacheIndex with emoji ---
let emoji = "Hi😀🎉"
emoji.cacheIndex()
expectEq(emoji.size, 4, "cached emoji .size")
expectEq(emoji[0], "H", "cached emoji index 0")
expectEq(emoji[1], "i", "cached emoji index 1")
expectEq(emoji[2], "😀", "cached emoji index 2")
expectEq(emoji[3], "🎉", "cached emoji index 3")
expectEq(emoji[2..=3], "😀🎉", "cached emoji slice")

// --- Section: cacheIndex returns self (chaining) ---
let chained = "测试链式".cacheIndex()
expectEq(chained, "测试链式", "cacheIndex returns self")
expectEq(chained[0], "测", "chained cacheIndex index 0")
expectEq(chained[3], "式", "chained cacheIndex index 3")

// --- Section: Empty string with cacheIndex ---
let empty = ""
empty.cacheIndex()
expectEq(empty.size, 0, "cached empty .size")

// --- Section: Single char with cacheIndex ---
let single = "X"
single.cacheIndex()
expectEq(single.size, 1, "cached single .size")
expectEq(single[0], "X", "cached single index 0")

let singleCjk = "龙"
singleCjk.cacheIndex()
expectEq(singleCjk.size, 1, "cached single CJK .size")
expectEq(singleCjk[0], "龙", "cached single CJK index 0")

// --- Section: Consistency without vs with cacheIndex ---
let s = "café☕🌍xyz"
expectEq(s[0], "c", "uncached s[0]")
expectEq(s[3], "é", "uncached s[3]")
expectEq(s[4], "☕", "uncached s[4]")
expectEq(s[5], "🌍", "uncached s[5]")
expectEq(s[6], "x", "uncached s[6]")
let uncachedSize = s.size

s.cacheIndex()
expectEq(s[0], "c", "cached s[0]")
expectEq(s[3], "é", "cached s[3]")
expectEq(s[4], "☕", "cached s[4]")
expectEq(s[5], "🌍", "cached s[5]")
expectEq(s[6], "x", "cached s[6]")
expectEq(s.size, uncachedSize, "cached size matches uncached")

// --- Section: cacheIndex with for-in iteration ---
let chars = "你好世"
chars.cacheIndex()
var collected = ""
for (i in 0..chars.size) {
    collected = collected + chars[i]
}
expectEq(collected, "你好世", "cached for-in UTF-8 chars")

// --- Section: Repeated cacheIndex calls (idempotent) ---
let rep = "abcdef"
rep.cacheIndex()
rep.cacheIndex()
expectEq(rep[0], "a", "double cacheIndex index 0")
expectEq(rep[5], "f", "double cacheIndex index 5")
expectEq(rep.size, 6, "double cacheIndex .size")

// --- Section: .size caching (without cacheIndex) ---
// Verify that .size is cached after first access
let sizeTest = "你好世界ABC"
let s1 = sizeTest.size
let s2 = sizeTest.size
expectEq(s1, 7, ".size first call")
expectEq(s2, 7, ".size second call (cached)")
expectEq(s1, s2, ".size consistent")

if (!__test_failed) {
    println("PASS: 77_string_cache_index")
}
