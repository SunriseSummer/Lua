dofile("cangjie-tests/_testing.cj")

// Test: Rune type (character type)
// Rule: only r'x' / r"x" is a Rune literal (compiles to integer code point);
// 'x' and "x" are String literals.

// -- Section: Rune literal with r prefix -> integer code point --

let a: Rune = r'a'
expectEq(a, 97, "r'a' == 97")

let b: Rune = r"b"
expectEq(b, 98, "r\"b\" == 98")

// -- Section: escape sequences --

let slash: Rune = r'\\'
expectEq(slash, 92, "r'\\\\' == 92")

let newLine: Rune = r'\n'
expectEq(newLine, 10, "r'\\n' == 10")

let tab: Rune = r'\t'
expectEq(tab, 9, "r'\\t' == 9")

// -- Section: Unicode escape sequences --

let he: Rune = r'\u{4f60}'
expectEq(he, 0x4f60, "r'\\u{4f60}' == 0x4f60")

let llo: Rune = r'\u{597d}'
expectEq(llo, 0x597d, "r'\\u{597d}' == 0x597d")

let dollar: Rune = r'\u{24}'
expectEq(dollar, 0x24, "r'\\u{24}' == 0x24")

let emoji: Rune = r'\u{1F600}'
expectEq(emoji, 0x1F600, "r'\\u{1F600}' emoji code point")

// -- Section: Rune comparison operations (integer comparisons) --

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

// -- Section: Rune() conversion function (code point -> string) --

let r1 = Rune(65)
expectEq(r1, "A", "Rune(65) == 'A'")

let r2 = Rune(0x4E50)
expectEq(r2, "乐", "Rune(0x4E50) == '乐'")

// Rune() from Rune literal (integer -> string)
expectEq(Rune(r'A'), "A", "Rune(r'A') == 'A'")
expectEq(Rune(r'\u{4f60}'), "你", "Rune(r'你') == '你'")

// -- Section: Int64() from Rune (passthrough since r'x' is already integer) --

let cp1 = Int64(r'A')
expectEq(cp1, 65, "Int64(r'A') == 65")

let cp2 = Int64(r'\u{4E50}')
expectEq(cp2, 0x4E50, "Int64(r'\\u{4E50}') == 0x4E50")

// -- Section: Rune in string interpolation (use Rune() to convert) --

let greeting: Rune = r'\u{4f60}'
let msg = "你好: ${Rune(greeting)}"
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
