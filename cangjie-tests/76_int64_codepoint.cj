dofile("cangjie-tests/_testing.cj")

// Test: Int64 and Rune conversion with strict r'x' rule
// r'x' is a Rune literal (compiles to integer code point)
// 'x' and "x" are String literals
// Int64(String) parses as number first, falls back to code point for non-numeric

// --- Section: r'x' Rune literals -> integer code points ---
expectEq(r'0', 48, "r'0' == 48")
expectEq(r'A', 65, "r'A' == 65")
expectEq(r'a', 97, "r'a' == 97")
expectEq(r' ', 32, "r' ' == 32")
expectEq(r'-', 45, "r'-' == 45")

// Int64 of Rune literal is integer passthrough
expectEq(Int64(r'0'), 48, "Int64(r'0') == 48")
expectEq(Int64(r'A'), 65, "Int64(r'A') == 65")

// --- Section: String '0' and "0" -> number parse ---
expectEq(Int64('0'), 0, "Int64('0') == 0")
expectEq(Int64("0"), 0, "Int64(\"0\") == 0")
expectEq(Int64("123"), 123, "Int64(\"123\") == 123")
expectEq(Int64("-42"), -42, "Int64(\"-42\") == -42")

// --- Section: Non-numeric single-char string -> code point fallback ---
expectEq(Int64("A"), 65, "Int64(\"A\") code point fallback")
expectEq(Int64("z"), 122, "Int64(\"z\") code point fallback")
expectEq(Int64("乐"), 0x4E50, "Int64(\"乐\") unicode fallback")

// --- Section: String.toRune() -> code point for all chars including digits ---
expectEq("0".toRune(), 48, "\"0\".toRune() == 48")
expectEq("A".toRune(), 65, "\"A\".toRune() == 65")
expectEq("乐".toRune(), 0x4E50, "\"乐\".toRune() == 0x4E50")

// --- Section: String indexing + toRune ---
let text = "Hello"
expectEq(text[0].toRune(), 72, "text[0].toRune() H=72")
expectEq(text[1].toRune(), 101, "text[1].toRune() e=101")

// Digit chars: Int64 parses as number, toRune returns code point
let digits = "0123456789"
expectEq(Int64(digits[0]), 0, "Int64(digits[0]) = 0 (number parse)")
expectEq(digits[0].toRune(), 48, "digits[0].toRune() = 48 (code point)")

// --- Section: Round-trip ---
let cp = r'A'
let r = Rune(cp)
expectEq(r, "A", "Rune(r'A') == \"A\"")
expectEq(r.toRune(), 65, "\"A\".toRune() == 65")

// --- Section: Float truncation ---
expectEq(Int64(3.14), 3, "Int64(3.14) truncates")

if (!__test_failed) {
    println("PASS: 76_int64_codepoint")
}
