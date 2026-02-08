dofile("cangjie-tests/_testing.cj")

// Test: Int64 and Rune conversion with strict r'x' rule
// r'x' is a Rune literal (compiles to integer code point)
// 'x' and "x" are String literals
// Int64(String) parses as number only, errors if parse fails

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

// --- Section: Int64(String) errors on non-numeric strings ---
expectRuntimeError("Int64 non-numeric char", 'let x = Int64("A")', "cannot convert")
expectRuntimeError("Int64 non-numeric unicode", 'let x = Int64("乐")', "cannot convert")
expectRuntimeError("Int64 non-numeric z", 'let x = Int64("z")', "cannot convert")

// --- Section: Rune() from string -> code point for all chars including digits ---
expectEq(Rune("0"), 48, "Rune(\"0\") == 48")
expectEq(Rune("A"), 65, "Rune(\"A\") == 65")
expectEq(Rune("乐"), 0x4E50, "Rune(\"乐\") == 0x4E50")

// --- Section: String indexing + Rune() ---
let text = "Hello"
expectEq(Rune(text[0]), 72, "Rune(text[0]) H=72")
expectEq(Rune(text[1]), 101, "Rune(text[1]) e=101")

// Digit chars: Int64 parses as number, Rune() returns code point
let digits = "0123456789"
expectEq(Int64(digits[0]), 0, "Int64(digits[0]) = 0 (number parse)")
expectEq(Rune(digits[0]), 48, "Rune(digits[0]) = 48 (code point)")

// --- Section: Round-trip ---
let cp = r'A'
let r = Rune(cp)
expectEq(r, "A", "Rune(r'A') == \"A\"")
expectEq(Rune(r), 65, "Rune(\"A\") == 65")

// --- Section: Float truncation ---
expectEq(Int64(3.14), 3, "Int64(3.14) truncates")

if (!__test_failed) {
    println("PASS: 76_int64_codepoint")
}
