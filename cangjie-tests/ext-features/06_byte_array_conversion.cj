dofile("cangjie-tests/_testing.cj")

// Extended feature: String <-> Array<Byte> conversion with dynamic features
// This test exercises the Lua-enhanced byte array manipulation

// --- Section: Manual byte array construction and conversion ---
// Build a byte array manually using dynamic table features
var byteArr = {}
byteArr[0] = 72
byteArr[1] = 105
byteArr.size = 2
byteArr.__n = 2
let greeting = String(byteArr)
expectEq(greeting, "Hi", "manual byte array -> String")

// --- Section: Modify bytes then convert ---
var bytes = "Hello".toArray()
// Uppercase 'e' to 'E' by changing byte value
bytes[1] = 69  // 'E' = 69
let modified = String(bytes)
expectEq(modified, "HEllo", "modify byte then convert back")

// --- Section: Concatenate byte arrays ---
let b1 = "Hello".toArray()
let b2 = " World".toArray()
var combined = {}
var idx = 0
for (i in 0..b1.size) {
    combined[idx] = b1[i]
    idx = idx + 1
}
for (i in 0..b2.size) {
    combined[idx] = b2[i]
    idx = idx + 1
}
combined.size = idx
combined.__n = idx
let concatResult = String(combined)
expectEq(concatResult, "Hello World", "concatenate byte arrays")

// --- Section: Byte-level string inspection ---
let s = "AB"
let bytesOfAB = s.toArray()
expectEq(bytesOfAB[0], 65, "A = 65")
expectEq(bytesOfAB[1], 66, "B = 66")

// Verify UTF-8 multi-byte structure
let utf8 = "é"  // 2-byte UTF-8: 0xC3 0xA9
let eBytes = utf8.toArray()
expectTrue(eBytes.size == 2, "é is 2 bytes")
expectEq(eBytes[0], 0xC3, "é byte 0")
expectEq(eBytes[1], 0xA9, "é byte 1")

// Round-trip via bytes
let eRestored = String(eBytes)
expectEq(eRestored, "é", "é round-trip")

// --- Section: Backward compatibility with __cangjie_string_from_byte_array ---
let bcResult = __cangjie_string_from_byte_array(eBytes)
expectEq(bcResult, "é", "backward compat __cangjie_string_from_byte_array")

if (!__test_failed) {
    println("PASS: ext-features/06_byte_array_conversion")
}
