dofile("cangjie-tests/_testing.cj")

// Test: Array<Byte> type and String <-> byte array conversion

// --- Section: String to Array<Byte> via toArray ---
let s = "Hello"
let bytes = s.toArray()
expectEq(bytes.size, 5, "toArray ASCII byte count")
expectEq(bytes[0], 72, "byte H = 72")
expectEq(bytes[1], 101, "byte e = 101")
expectEq(bytes[2], 108, "byte l = 108")
expectEq(bytes[3], 108, "byte l = 108")
expectEq(bytes[4], 111, "byte o = 111")

// --- Section: CJK string to bytes ---
let cjk = "你"
let cjkBytes = cjk.toArray()
expectEq(cjkBytes.size, 3, "'你' is 3 bytes in UTF-8")
expectEq(cjkBytes[0], 0xE4, "你 byte 0 = 0xE4")
expectEq(cjkBytes[1], 0xBD, "你 byte 1 = 0xBD")
expectEq(cjkBytes[2], 0xA0, "你 byte 2 = 0xA0")

// --- Section: Emoji to bytes ---
let emoji = "😀"
let emojiBytes = emoji.toArray()
expectEq(emojiBytes.size, 4, "😀 is 4 bytes in UTF-8")
expectEq(emojiBytes[0], 0xF0, "😀 byte 0")
expectEq(emojiBytes[1], 0x9F, "😀 byte 1")
expectEq(emojiBytes[2], 0x98, "😀 byte 2")
expectEq(emojiBytes[3], 0x80, "😀 byte 3")

// --- Section: Array<Byte> back to String ---
let byteArr = s.toArray()
let restored = __cangjie_string_from_byte_array(byteArr)
expectEq(restored, "Hello", "byte array -> String round trip")

let cjkRestored = __cangjie_string_from_byte_array(cjkBytes)
expectEq(cjkRestored, "你", "CJK byte array -> String round trip")

let emojiRestored = __cangjie_string_from_byte_array(emojiBytes)
expectEq(emojiRestored, "😀", "emoji byte array -> String round trip")

// --- Section: Mixed string round trip ---
let mixed = "Hello你好😀"
let mixedBytes = mixed.toArray()
let mixedRestored = __cangjie_string_from_byte_array(mixedBytes)
expectEq(mixedRestored, "Hello你好😀", "mixed string round trip")

// --- Section: toRuneArray ---
let runes = "AB你好".toRuneArray()
expectEq(runes.size, 4, "toRuneArray size")
expectEq(runes[0], "A", "toRuneArray[0]")
expectEq(runes[1], "B", "toRuneArray[1]")
expectEq(runes[2], "你", "toRuneArray[2]")
expectEq(runes[3], "好", "toRuneArray[3]")

// --- Section: Empty string ---
let emptyBytes = "".toArray()
expectEq(emptyBytes.size, 0, "empty toArray size")

let emptyRunes = "".toRuneArray()
expectEq(emptyRunes.size, 0, "empty toRuneArray size")

let emptyRestored = __cangjie_string_from_byte_array(emptyBytes)
expectEq(emptyRestored, "", "empty byte array round trip")

// --- Section: Array<Byte> iteration ---
let iterBytes = "Hi".toArray()
var sum = 0
for (i in 0..iterBytes.size) {
    sum = sum + iterBytes[i]
}
expectEq(sum, 72 + 105, "iterate byte array sum")

if (!__test_failed) {
    println("PASS: 74_byte_array")
}
