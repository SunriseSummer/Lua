dofile("cangjie-tests/_testing.cj")

// Test: Int64 code point conversion for single-character strings
// Single UTF-8 character strings are treated as Rune (returns code point).
// Multi-character strings are parsed as numbers.

// --- Section: ASCII digits as code points ---
expectEq(Int64('0'), 48, "Int64('0') code point")
expectEq(Int64('1'), 49, "Int64('1') code point")
expectEq(Int64('9'), 57, "Int64('9') code point")

// --- Section: ASCII letters as code points ---
expectEq(Int64('A'), 65, "Int64('A') code point")
expectEq(Int64('Z'), 90, "Int64('Z') code point")
expectEq(Int64('a'), 97, "Int64('a') code point")
expectEq(Int64('z'), 122, "Int64('z') code point")

// --- Section: Special ASCII characters ---
expectEq(Int64(' '), 32, "Int64(' ') space")
expectEq(Int64('-'), 45, "Int64('-') minus")
expectEq(Int64('.'), 46, "Int64('.') dot")
expectEq(Int64('+'), 43, "Int64('+') plus")

// --- Section: Multi-char strings as numbers ---
expectEq(Int64("10"), 10, "Int64(\"10\") number")
expectEq(Int64("123"), 123, "Int64(\"123\") number")
expectEq(Int64("-42"), -42, "Int64(\"-42\") negative")
expectEq(Int64("1234567"), 1234567, "Int64(\"1234567\") large number")

// --- Section: Unicode characters ---
expectEq(Int64('乐'), 0x4E50, "Int64('乐') unicode")
expectEq(Int64('你'), 0x4F60, "Int64('你') unicode")

// --- Section: String indexing returns Rune-like values ---
let text = "Hello"
expectEq(Int64(text[0]), 72, "Int64(text[0]) H=72")
expectEq(Int64(text[1]), 101, "Int64(text[1]) e=101")
expectEq(Int64(text[4]), 111, "Int64(text[4]) o=111")

// --- Section: Digit chars from string indexing ---
let digits = "0123456789"
expectEq(Int64(digits[0]), 48, "digit[0] code point")
expectEq(Int64(digits[5]), 53, "digit[5] code point")
expectEq(Int64(digits[9]), 57, "digit[9] code point")

// --- Section: Round-trip Rune conversion ---
let cp = Int64('A')
let r = Rune(cp)
expectEq(r, "A", "Int64->Rune round trip A")
expectEq(Int64(r), 65, "Rune->Int64 round trip A")

let cp2 = Int64('好')
let r2 = Rune(cp2)
expectEq(r2, "好", "Int64->Rune round trip 好")

// --- Section: Float from number string ---
expectEq(Int64(3.14), 3, "Int64(3.14) truncates")

if (!__test_failed) {
    println("PASS: 76_int64_codepoint")
}
