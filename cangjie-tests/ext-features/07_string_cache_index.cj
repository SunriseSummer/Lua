dofile("cangjie-tests/_testing.cj")

// Test: Extended feature - cacheIndex() for O(1) string indexing
// This is a Cangjie superset feature for performance optimization

// --- Section: Basic cacheIndex functionality ---
let s = "你好世界Hello"
s.cacheIndex()

// After cacheIndex, indexing should be O(1) via offset table
expectEq(s[0], "你", "cached index 0")
expectEq(s[3], "界", "cached index 3")
expectEq(s[4], "H", "cached index 4")
expectEq(s[8], "o", "cached index 8")
expectEq(s.size, 9, "cached size")

// --- Section: cacheIndex with slicing ---
expectEq(s[0..4], "你好世界", "cached slice CJK part")
expectEq(s[4..=8], "Hello", "cached slice ASCII part")
expectEq(s[2..=6], "世界Hel", "cached slice cross boundary")

// --- Section: cacheIndex chaining in expressions ---
let result = "HELLO".cacheIndex().toAsciiLower()
expectEq(result, "hello", "cacheIndex chain toLower")

// --- Section: cacheIndex with various string operations ---
let cached = "Hello World".cacheIndex()
expectTrue(cached.contains("World"), "cached contains")
expectTrue(cached.startsWith("Hello"), "cached startsWith")
expectTrue(cached.endsWith("World"), "cached endsWith")
expectEq(cached.indexOf("World"), 6, "cached indexOf")

// --- Section: cacheIndex for repeated random access ---
let longMixed = "ABCDE你好世界FGHIJ"
longMixed.cacheIndex()
// Access in reverse order (benefits from O(1) lookup)
expectEq(longMixed[13], "J", "cached reverse access last")
expectEq(longMixed[9], "F", "cached reverse access mid")
expectEq(longMixed[5], "你", "cached reverse access CJK")
expectEq(longMixed[0], "A", "cached reverse access first")

// --- Section: cacheIndex with emoji sequences ---
let emojiStr = "🌍🌎🌏🌐"
emojiStr.cacheIndex()
expectEq(emojiStr.size, 4, "cached emoji size")
expectEq(emojiStr[0], "🌍", "cached emoji index 0")
expectEq(emojiStr[1], "🌎", "cached emoji index 1")
expectEq(emojiStr[2], "🌏", "cached emoji index 2")
expectEq(emojiStr[3], "🌐", "cached emoji index 3")
expectEq(emojiStr[1..3], "🌎🌏", "cached emoji slice")

// --- Section: cacheIndex with for-in loop ---
let loopStr = "αβγδε"
loopStr.cacheIndex()
var collected = ""
for (i in 0..loopStr.size) {
    collected = collected + loopStr[i]
}
expectEq(collected, "αβγδε", "cached for-in Greek chars")

if (!__test_failed) {
    println("PASS: ext-features/07_string_cache_index")
}
