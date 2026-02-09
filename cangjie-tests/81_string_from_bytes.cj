dofile("cangjie-tests/_testing.cj")

// Test: String(bytes) conversion from UTF-8 byte arrays

// --- Section: Basic ASCII byte array conversion ---
let ascii = "Hello"
let bytes = ascii.toArray()
let restored = String(bytes)
expectEq(restored, "Hello", "ASCII round-trip via String(bytes)")

// --- Section: CJK byte array conversion ---
let cjk = "你好世界"
let cjkBytes = cjk.toArray()
let cjkRestored = String(cjkBytes)
expectEq(cjkRestored, "你好世界", "CJK round-trip via String(bytes)")

// --- Section: Emoji byte array conversion ---
let emoji = "😀🎉"
let emojiBytes = emoji.toArray()
let emojiRestored = String(emojiBytes)
expectEq(emojiRestored, "😀🎉", "emoji round-trip via String(bytes)")

// --- Section: Mixed content round-trip ---
let mixed = "Hello你好😀"
let mixedBytes = mixed.toArray()
let mixedRestored = String(mixedBytes)
expectEq(mixedRestored, mixed, "mixed content round-trip")

// --- Section: Empty byte array ---
let emptyBytes = "".toArray()
let emptyRestored = String(emptyBytes)
expectEq(emptyRestored, "", "empty byte array -> empty string")

// --- Section: Single byte ---
let singleBytes = "A".toArray()
let singleRestored = String(singleBytes)
expectEq(singleRestored, "A", "single byte round-trip")

// --- Section: 2-byte UTF-8 character ---
let twoByteStr = "é"
let twoBytes = twoByteStr.toArray()
expectEq(twoBytes.size, 2, "é is 2 bytes")
let twoRestored = String(twoBytes)
expectEq(twoRestored, "é", "2-byte char round-trip")

// --- Section: 3-byte UTF-8 character ---
let threeByteStr = "€"
let threeBytes = threeByteStr.toArray()
expectEq(threeBytes.size, 3, "€ is 3 bytes")
let threeRestored = String(threeBytes)
expectEq(threeRestored, "€", "3-byte char round-trip")

// --- Section: 4-byte UTF-8 character ---
let fourByteStr = "😀"
let fourBytes = fourByteStr.toArray()
expectEq(fourBytes.size, 4, "😀 is 4 bytes")
let fourRestored = String(fourBytes)
expectEq(fourRestored, "😀", "4-byte char round-trip")

// --- Section: String() still works for other types ---
expectEq(String(42), "42", "String(int) still works")
expectEq(String(3.14), "3.14", "String(float) still works")
expectEq(String(true), "true", "String(bool) still works")
expectEq(String(r'A'), "A", "String(Rune) still works")
expectEq(String("hello"), "hello", "String(string) identity")

if (!__test_failed) {
    println("PASS: 81_string_from_bytes")
}
