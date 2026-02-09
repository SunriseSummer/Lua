dofile("cangjie-tests/_testing.cj")

// Test: String indexing returns Rune, range indexing returns String

// --- Section: Single index returns Rune type ---
let s = "hello"
expectTrue(type(s[0]) == "Rune", "s[0] is Rune type")
expectTrue(type(s[4]) == "Rune", "s[4] is Rune type")

// --- Section: Range index returns String type ---
expectTrue(type(s[0..3]) == "string", "s[0..3] is string type")
expectTrue(type(s[0..=0]) == "string", "s[0..=0] is string type (single char range)")
expectTrue(type(s[2..2]) == "string", "s[2..2] is string type (empty range)")

// --- Section: Rune comparison with literals ---
expectEq(s[0], r'h', "s[0] == r'h'")
expectEq(s[1], r'e', "s[1] == r'e'")
expectEq(s[4], r'o', "s[4] == r'o'")
expectTrue(s[0] == r'h', "s[0] == r'h' via ==")
expectTrue(s[0] != r'x', "s[0] != r'x'")
expectTrue(s[0] < r'z', "s[0] < r'z'")
expectTrue(s[0] > r'a', "s[0] > r'a'")
expectTrue(s[0] >= r'h', "s[0] >= r'h'")
expectTrue(s[0] <= r'h', "s[0] <= r'h'")

// --- Section: Rune from CJK string index ---
let cjk = "你好世界"
expectEq(Int64(cjk[0]), 0x4F60, "Int64(cjk[0]) code point")
expectEq(Int64(cjk[1]), 0x597D, "Int64(cjk[1]) code point")

// --- Section: Rune from emoji string index ---
let emoji = "😀🎉"
expectEq(Int64(emoji[0]), 0x1F600, "Int64(emoji[0]) code point")
expectEq(Int64(emoji[1]), 0x1F389, "Int64(emoji[1]) code point")

// --- Section: String(Rune) conversion from index ---
expectEq(String(s[0]), "h", "String(s[0]) == 'h'")
expectEq(String(cjk[0]), "你", "String(cjk[0]) == '你'")
expectEq(String(emoji[0]), "😀", "String(emoji[0]) == '😀'")

// --- Section: Rune identity via Rune() on indexed value ---
expectEq(Rune(s[0]), r'h', "Rune(s[0]) == r'h'")
expectEq(Rune(cjk[0]), r'\u{4F60}', "Rune(cjk[0]) identity")
expectEq(s[0], Rune(s[0]), "s[0] == Rune(s[0]) identity")

// --- Section: Range slice is always String even for single char ---
expectTrue(type(s[0..=0]) == "string", "single char inclusive range is string")
expectTrue(type(s[0..1]) == "string", "single char exclusive range is string")
expectEq(s[0..=0], "h", "s[0..=0] == 'h' (string)")
expectEq(s[0..1], "h", "s[0..1] == 'h' (string)")

// --- Section: String + Rune concatenation ---
let r = s[0]
expectEq("prefix" + r, "prefixh", "string + Rune concat")
expectEq(r + "suffix", "hsuffix", "Rune + string concat")
expectEq(String(r) + "!", "h!", "String(Rune) + string")

// --- Section: for-in string iterates as Rune ---
var runeCount = 0
var firstRune = r'\0'
var secondRune = r'\0'
var thirdRune = r'\0'
for (ch in "abc") {
    if (runeCount == 0) { firstRune = ch }
    if (runeCount == 1) { secondRune = ch }
    if (runeCount == 2) { thirdRune = ch }
    runeCount = runeCount + 1
}
expectEq(runeCount, 3, "for-in string produces 3 Rune values")
expectEq(firstRune, r'a', "for-in rune 0")
expectEq(secondRune, r'b', "for-in rune 1")
expectEq(thirdRune, r'c', "for-in rune 2")
expectTrue(type(firstRune) == "Rune", "for-in element is Rune type")

// --- Section: for-in string with CJK ---
var cjkFirst = r'\0'
var cjkSecond = r'\0'
var cjkCount = 0
for (ch in "你好") {
    if (cjkCount == 0) { cjkFirst = ch }
    if (cjkCount == 1) { cjkSecond = ch }
    cjkCount = cjkCount + 1
}
expectEq(cjkCount, 2, "for-in CJK produces 2 Runes")
expectEq(cjkFirst, r'\u{4F60}', "for-in CJK rune 0")
expectEq(cjkSecond, r'\u{597D}', "for-in CJK rune 1")

// --- Section: for-in string with mixed content ---
var mixedCount = 0
var mixR0 = r'\0'
var mixR1 = r'\0'
var mixR2 = r'\0'
for (ch in "A你😀") {
    if (mixedCount == 0) { mixR0 = ch }
    if (mixedCount == 1) { mixR1 = ch }
    if (mixedCount == 2) { mixR2 = ch }
    mixedCount = mixedCount + 1
}
expectEq(mixedCount, 3, "for-in mixed produces 3 Runes")
expectEq(mixR0, r'A', "for-in mixed rune 0")
expectEq(mixR1, r'\u{4F60}', "for-in mixed rune 1")
expectEq(mixR2, r'\u{1F600}', "for-in mixed rune 2")

// --- Section: for-in empty string ---
var emptyCount = 0
for (ch in "") {
    emptyCount = emptyCount + 1
}
expectEq(emptyCount, 0, "for-in empty string has 0 iterations")

// --- Section: Collect string via for-in and String() ---
var rebuilt = ""
for (ch in "Hello") {
    rebuilt = rebuilt + String(ch)
}
expectEq(rebuilt, "Hello", "rebuild string from for-in Rune")

if (!__test_failed) {
    println("PASS: 80_string_index_rune")
}
