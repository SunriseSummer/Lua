dofile("cangjie-tests/_testing.cj")

// Test: Int64 Rune-to-code-point conversion
// Validates that Int64() on single characters returns Unicode code points

// --- Section: ASCII digit characters ---
expectEq(Int64('0'), 48, "Int64('0') code point")
expectEq(Int64('1'), 49, "Int64('1') code point")
expectEq(Int64('2'), 50, "Int64('2') code point")
expectEq(Int64('3'), 51, "Int64('3') code point")
expectEq(Int64('4'), 52, "Int64('4') code point")
expectEq(Int64('5'), 53, "Int64('5') code point")
expectEq(Int64('6'), 54, "Int64('6') code point")
expectEq(Int64('7'), 55, "Int64('7') code point")
expectEq(Int64('8'), 56, "Int64('8') code point")
expectEq(Int64('9'), 57, "Int64('9') code point")

// --- Section: ASCII letter characters ---
expectEq(Int64('A'), 65, "Int64('A') code point")
expectEq(Int64('Z'), 90, "Int64('Z') code point")
expectEq(Int64('a'), 97, "Int64('a') code point")
expectEq(Int64('z'), 122, "Int64('z') code point")

// --- Section: Special ASCII characters ---
expectEq(Int64(' '), 32, "Int64(' ') space")
expectEq(Int64('-'), 45, "Int64('-') minus")
expectEq(Int64('.'), 46, "Int64('.') period")
expectEq(Int64('/'), 47, "Int64('/') slash")
expectEq(Int64('!'), 33, "Int64('!') exclaim")
expectEq(Int64('@'), 64, "Int64('@') at")

// --- Section: Single character from string indexing ---
let text = "0123456789"
expectEq(Int64(text[0]), 48, "Int64(text[0]) = '0' code point")
expectEq(Int64(text[1]), 49, "Int64(text[1]) = '1' code point")
expectEq(Int64(text[9]), 57, "Int64(text[9]) = '9' code point")

let alpha = "AaBbZz"
expectEq(Int64(alpha[0]), 65, "Int64('A') from string index")
expectEq(Int64(alpha[1]), 97, "Int64('a') from string index")
expectEq(Int64(alpha[4]), 90, "Int64('Z') from string index")
expectEq(Int64(alpha[5]), 122, "Int64('z') from string index")

// --- Section: Multi-character string remains numeric parsing ---
expectEq(Int64("123"), 123, "Int64(\"123\") numeric parse")
expectEq(Int64("42"), 42, "Int64(\"42\") numeric parse")
expectEq(Int64("-7"), -7, "Int64(\"-7\") negative")
expectEq(Int64("100"), 100, "Int64(\"100\")")

// --- Section: Unicode characters ---
expectEq(Int64('乐'), 0x4E50, "Int64('乐') CJK")
expectEq(Int64('中'), 0x4E2D, "Int64('中') CJK")

// --- Section: Rune round-trip ---
let cp = Int64('A')
let back = Rune(cp)
expectEq(back, 'A', "Rune round-trip: A")

let cp2 = Int64('9')
let back2 = Rune(cp2)
expectEq(back2, '9', "Rune round-trip: 9")

// --- Section: Using Int64 as array index (key use case) ---
let lookup = Array(128, 0)
lookup[48] = 10  // '0'
lookup[49] = 11  // '1'
lookup[65] = 20  // 'A'

expectEq(lookup[Int64('0')], 10, "lookup[Int64('0')]")
expectEq(lookup[Int64('1')], 11, "lookup[Int64('1')]")
expectEq(lookup[Int64('A')], 20, "lookup[Int64('A')]")

// Test inside loop
let input = "01A"
var sum = 0
var idx = 0
while (idx < input.size) {
    sum = sum + lookup[Int64(input[idx])]
    idx = idx + 1
}
expectEq(sum, 41, "sum of lookup values: 10+11+20")

if (!__test_failed) {
    println("PASS: 73_int64_rune_codepoint")
}
