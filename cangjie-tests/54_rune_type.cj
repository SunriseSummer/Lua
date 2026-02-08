dofile("cangjie-tests/_testing.cj")

// Test: Rune type (character type)

// -- Section: Rune literal with r prefix --

// Single character with single quotes
let a: Rune = r'a'
expectEq(a, "a", "r'a'")

// Single character with double quotes
let b: Rune = r"b"
expectEq(b, "b", "r\"b\"")

// -- Section: escape sequences --

let slash: Rune = r'\\'
expectEq(slash, "\\", "r'\\\\'")

let newLine: Rune = r'\n'
expectEq(newLine, "\n", "r'\\n'")

let tab: Rune = r'\t'
expectEq(tab, "\t", "r'\\t'")

// -- Section: Unicode escape sequences --

let he: Rune = r'\u{4f60}'
expectEq(he, "你", "r'\\u{4f60}' == 你")

let llo: Rune = r'\u{597d}'
expectEq(llo, "好", "r'\\u{597d}' == 好")

let dollar: Rune = r'\u{24}'
expectEq(dollar, "$", "r'\\u{24}' == $")

let emoji: Rune = r'\u{1F600}'
expectEq(emoji, "😀", "r'\\u{1F600}' emoji")

// -- Section: Rune without r prefix (also valid) --

let c1: Rune = '中'
expectEq(c1, "中", "'中' Rune literal")

let c2: Rune = 'Z'
expectEq(c2, "Z", "'Z' Rune literal")

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
expectTrue(cn1 < cn2, "'你' < '好'")

// -- Section: Rune() conversion function --

let r1 = Rune(65)
expectEq(r1, "A", "Rune(65) == 'A'")

let r2 = Rune(0x4E50)
expectEq(r2, "乐", "Rune(0x4E50) == '乐'")

// -- Section: Int64() from Rune --

let cp1 = Int64(r'A')
expectEq(cp1, 65, "Int64(r'A') == 65")

let cp2 = Int64(r'\u{4E50}')
expectEq(cp2, 0x4E50, "Int64(r'\\u{4E50}') == 0x4E50")

// -- Section: Rune in string interpolation --

let greeting: Rune = r'\u{4f60}'
let msg = "你好: ${greeting}"
expectEq(msg, "你好: 你", "Rune in string interpolation")

if (!__test_failed) {
    println("PASS: 54_rune_type")
}
