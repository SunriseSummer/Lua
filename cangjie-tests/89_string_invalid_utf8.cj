dofile("cangjie-tests/_testing.cj")

// Test: Invalid UTF-8 bytes are handled consistently across string APIs

// --- Section: Construct string from invalid UTF-8 bytes ---
let invalidBytes: Array<Byte> = [0xC0, 0xAF, 0x61]  // invalid sequence + 'a'
let invalidStr = String(invalidBytes)
expectEq(invalidStr.size, 3, "invalid UTF-8 size counts bytes")
expectEq(Int64(invalidStr[0]), 0xFFFD, "invalid byte 0 replacement rune")
expectEq(Int64(invalidStr[1]), 0xFFFD, "invalid byte 1 replacement rune")
expectEq(invalidStr[2], r'a', "valid ASCII after invalid bytes")

// --- Section: toRuneArray uses replacement runes ---
let invalidRunes = invalidStr.toRuneArray()
expectEq(invalidRunes.size, 3, "invalid toRuneArray size")
expectEq(Int64(invalidRunes[0]), 0xFFFD, "invalid rune array 0")
expectEq(Int64(invalidRunes[1]), 0xFFFD, "invalid rune array 1")
expectEq(invalidRunes[2], r'a', "invalid rune array 2")

// --- Section: split into chars preserves raw bytes ---
let splitChars = invalidStr.split("")
expectEq(splitChars.size, 3, "split invalid bytes size")
let firstBytes = splitChars[0].toArray()
expectEq(firstBytes.size, 1, "split invalid byte 0 length")
expectEq(firstBytes[0], 0xC0, "split invalid byte 0 value")
let secondBytes = splitChars[1].toArray()
expectEq(secondBytes[0], 0xAF, "split invalid byte 1 value")

// --- Section: cacheIndex keeps invalid-byte semantics ---
invalidStr.cacheIndex()
expectEq(invalidStr.size, 3, "cacheIndex invalid size")
expectEq(Int64(invalidStr[0]), 0xFFFD, "cacheIndex invalid rune 0")
expectEq(invalidStr[2], r'a', "cacheIndex valid rune")

if (!__test_failed) {
    println("PASS: 89_string_invalid_utf8")
}
