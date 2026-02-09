dofile("cangjie-tests/_testing.cj")

// Test: Int64 and Rune conversion — Rune is a distinct type
// r'x' is a Rune literal (distinct type, not integer)
// 'x' and "x" are String literals
// Int64(Rune) extracts code point; Int64(String) parses as number only

// --- Section: r'x' Rune literals are Rune type ---
expectEq(type(r'0'), "Rune", "type(r'0') == Rune")
expectEq(type(r'A'), "Rune", "type(r'A') == Rune")

// Rune != integer (strict type separation)
expectFalse(r'0' == 48, "r'0' != 48")
expectFalse(r'A' == 65, "r'A' != 65")

// Rune equality
expectTrue(r'0' == r'0', "r'0' == r'0'")
expectTrue(r'A' == r'A', "r'A' == r'A'")

// --- Section: Int64(Rune) extracts code point ---
expectEq(Int64(r'0'), 48, "Int64(r'0') == 48")
expectEq(Int64(r'A'), 65, "Int64(r'A') == 65")
expectEq(Int64(r'a'), 97, "Int64(r'a') == 97")
expectEq(Int64(r' '), 32, "Int64(r' ') == 32")
expectEq(Int64(r'-'), 45, "Int64(r'-') == 45")

// --- Section: String '0' and "0" -> number parse ---
expectEq(Int64('0'), 0, "Int64('0') == 0")
expectEq(Int64("0"), 0, "Int64(\"0\") == 0")
expectEq(Int64("123"), 123, "Int64(\"123\") == 123")
expectEq(Int64("-42"), -42, "Int64(\"-42\") == -42")

// --- Section: Int64(String) errors on non-numeric strings ---
expectRuntimeError("Int64 non-numeric char", 'let x = Int64("A")', "cannot convert")
expectRuntimeError("Int64 non-numeric unicode", 'let x = Int64("乐")', "cannot convert")
expectRuntimeError("Int64 non-numeric z", 'let x = Int64("z")', "cannot convert")

// --- Section: Rune() from string -> Rune instance ---
expectEq(Rune("0"), r'0', "Rune(\"0\") == r'0'")
expectEq(Rune("A"), r'A', "Rune(\"A\") == r'A'")
expectEq(Rune("乐"), r'乐', "Rune(\"乐\") == r'乐'")

// --- Section: String indexing + Rune() ---
let text = "Hello"
expectEq(Int64(Rune(text[0])), 72, "Int64(Rune(text[0])) H=72")
expectEq(Int64(Rune(text[1])), 101, "Int64(Rune(text[1])) e=101")

// Digit chars: Int64 parses string as number, Int64(Rune()) extracts code point
let digits = "0123456789"
expectEq(Int64(digits[0]), 0, "Int64(digits[0]) = 0 (number parse)")
expectEq(Int64(Rune(digits[0])), 48, "Int64(Rune(digits[0])) = 48 (code point)")

// --- Section: Round-trip ---
let cp = r'A'
expectEq(String(cp), "A", "String(r'A') == \"A\"")
expectEq(Rune("A"), r'A', "Rune(\"A\") == r'A'")
expectEq(Int64(Rune("A")), 65, "Int64(Rune(\"A\")) == 65")

// --- Section: Rune(Rune(x)) identity ---
expectEq(Rune(Rune(65)), Rune(65), "Rune(Rune(65)) == Rune(65)")
expectEq(Rune(Rune(65)), r'A', "Rune(Rune(65)) == r'A'")

// --- Section: Float truncation ---
expectEq(Int64(3.14), 3, "Int64(3.14) truncates")

if (!__test_failed) {
    println("PASS: 76_int64_codepoint")
}
