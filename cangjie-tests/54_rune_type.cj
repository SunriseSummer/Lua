dofile("cangjie-tests/_testing.cj")

// Test: Rune type (distinct type representing Unicode character)
// Rule: only r'x' / r"x" is a Rune literal;
// 'x' and "x" are String literals.
// Rune is semantically distinct from Int64 and String.

// -- Section: Rune literal with r prefix -> Rune instance --

let a: Rune = r'a'
expectEq(a, r'a', "r'a' == r'a'")
expectEq(type(a), "Rune", "type(r'a') == Rune")

let b: Rune = r"b"
expectEq(b, r'b', "r\"b\" == r'b'")

// -- Section: escape sequences --

let slash: Rune = r'\\'
expectEq(Int64(slash), 92, "Int64(r'\\\\') == 92")

let newLine: Rune = r'\n'
expectEq(Int64(newLine), 10, "Int64(r'\\n') == 10")

let tab: Rune = r'\t'
expectEq(Int64(tab), 9, "Int64(r'\\t') == 9")

// -- Section: Unicode escape sequences --

let he: Rune = r'\u{4f60}'
expectEq(Int64(he), 0x4f60, "Int64(r'\\u{4f60}') == 0x4f60")

let llo: Rune = r'\u{597d}'
expectEq(Int64(llo), 0x597d, "Int64(r'\\u{597d}') == 0x597d")

let dollar: Rune = r'\u{24}'
expectEq(Int64(dollar), 0x24, "Int64(r'\\u{24}') == 0x24")

let emoji: Rune = r'\u{1F600}'
expectEq(Int64(emoji), 0x1F600, "Int64(r'\\u{1F600}') emoji code point")

// -- Section: Rune comparison operations --

let x: Rune = r'a'
let y: Rune = r'b'
let z: Rune = r'a'

expectTrue(x < y, "r'a' < r'b'")
expectFalse(x > y, "r'a' > r'b'")
expectTrue(x <= y, "r'a' <= r'b'")
expectFalse(x >= y, "r'a' >= r'b'")
expectTrue(x == z, "r'a' == r'a'")
expectTrue(x != y, "r'a' != r'b'")

// Compare Unicode characters
let cn1: Rune = r'\u{4f60}'  // 你
let cn2: Rune = r'\u{597d}'  // 好
expectTrue(cn1 < cn2, "r'你' < r'好'")

// -- Section: Rune() construction --

// Rune(integer) -> Rune instance
let r1 = Rune(65)
expectEq(r1, r'A', "Rune(65) == r'A'")
expectEq(String(r1), "A", "String(Rune(65)) == \"A\"")

let r2 = Rune(0x4E50)
expectEq(String(r2), "乐", "String(Rune(0x4E50)) == '乐'")

// Rune(Rune) -> identity
expectEq(Rune(r'A'), r'A', "Rune(r'A') == r'A'")
expectEq(Rune(Rune(65)), Rune(65), "Rune(Rune(65)) == Rune(65)")
expectEq(Rune(Rune(65)), r'A', "Rune(Rune(65)) == r'A'")

// Rune(string) -> Rune instance from single-char string
expectEq(Rune('x'), r'x', "Rune('x') == r'x'")
expectEq(Rune("好"), r'好', "Rune(\"好\") == r'好'")
expectEq(Rune('0'), r'0', "Rune('0') == r'0'")
expectEq(Rune("A"), r'A', "Rune(\"A\") == r'A'")

// -- Section: Int64() extracts code point from Rune --

let cp1 = Int64(r'A')
expectEq(cp1, 65, "Int64(r'A') == 65")

let cp2 = Int64(r'\u{4E50}')
expectEq(cp2, 0x4E50, "Int64(r'\\u{4E50}') == 0x4E50")

// -- Section: String() converts Rune to character string --

expectEq(String(r'A'), "A", "String(r'A') == \"A\"")
expectEq(String(r'好'), "好", "String(r'好') == \"好\"")

// -- Section: tostring(Rune) returns character string --

expectEq(tostring(r'A'), "A", "tostring(r'A') == \"A\"")

// -- Section: Rune in string interpolation --

let greeting: Rune = r'\u{4f60}'
let msg = "你好: ${greeting}"
expectEq(msg, "你好: 你", "Rune in string interpolation")

// -- Section: String literals with single quotes (NOT Rune) --
// 'x' and "x" are both String literals
let s1 = 'A'
expectEq(s1, "A", "'A' is string")
let s2 = '中'
expectEq(s2, "中", "'中' is string")

if (!__test_failed) {
    println("PASS: 54_rune_type")
}
