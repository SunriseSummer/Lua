dofile("cangjie-tests/_testing.cj")

// Test: Native UTF-8 string support
// String indexing returns Rune (Unicode character), .size returns character count

// --- Section: ASCII strings ---
let ascii = "hello"
expectEq(ascii.size, 5, "ASCII .size")
expectEq(ascii[0], r'h', "ASCII index 0")
expectEq(ascii[4], r'o', "ASCII index 4")
expectTrue(type(ascii[0]) == "Rune", "ASCII index returns Rune type")
expectEq(ascii[0..3], "hel", "ASCII slice 0..3")
expectEq(ascii[0..=4], "hello", "ASCII inclusive slice")
expectTrue(type(ascii[0..3]) == "String", "ASCII slice returns String type")

// --- Section: CJK strings ---
let cjk = "你好世界"
expectEq(cjk.size, 4, "CJK .size is 4 characters")
expectEq(cjk[0], r'你', "CJK index 0 returns '你'")
expectEq(cjk[1], r'好', "CJK index 1 returns '好'")
expectEq(cjk[2], r'世', "CJK index 2 returns '世'")
expectEq(cjk[3], r'界', "CJK index 3 returns '界'")

// --- Section: CJK slicing (returns string) ---
expectEq(cjk[0..2], "你好", "CJK slice 0..2")
expectEq(cjk[1..3], "好世", "CJK slice 1..3")
expectEq(cjk[0..=3], "你好世界", "CJK inclusive slice full")
expectEq(cjk[2..=2], "世", "CJK inclusive slice single char (still string)")
expectTrue(type(cjk[2..=2]) == "String", "CJK single-char slice is String type")
expectEq(cjk[2..2], "", "CJK empty slice")

// --- Section: Mixed ASCII and CJK ---
let mixed = "Hello你好"
expectEq(mixed.size, 7, "mixed .size is 7")
expectEq(mixed[0], r'H', "mixed index 0")
expectEq(mixed[4], r'o', "mixed index 4")
expectEq(mixed[5], r'你', "mixed index 5 (CJK)")
expectEq(mixed[6], r'好', "mixed index 6 (CJK)")
expectEq(mixed[0..5], "Hello", "mixed slice ASCII part")
expectEq(mixed[5..=6], "你好", "mixed slice CJK part")

// --- Section: Emoji characters ---
let emoji = "Hi😀🎉"
expectEq(emoji.size, 4, "emoji .size is 4")
expectEq(emoji[0], r'H', "emoji index 0")
expectEq(emoji[1], r'i', "emoji index 1")
expectEq(emoji[2], r'😀', "emoji index 2")
expectEq(emoji[3], r'🎉', "emoji index 3")
expectEq(emoji[2..=3], "😀🎉", "emoji slice")

// --- Section: Indexed character is Rune ---
// String indexing returns Rune type. Compare with Rune literals.
expectEq(ascii[0], r'h', "ascii[0] == r'h'")
expectEq(cjk[0], r'你', "cjk[0] == Rune('你')")

// Compare Rune directly
expectTrue(ascii[0] == r'h', "indexed Rune == r'h'")
expectTrue(ascii[0] < r'z', "indexed Rune < r'z'")
expectTrue(ascii[4] > r'a', "indexed Rune > r'a'")

// Rune() identity on indexed Rune
expectEq(Rune(ascii[0]), r'h', "Rune(ascii[0]) == r'h'")

// Int64() extracts code point from indexed character (Rune)
expectEq(Int64(cjk[0]), 0x4F60, "Int64(cjk[0]) == 0x4F60 (你)")
expectEq(Int64(mixed[5]), 0x4F60, "Int64(mixed[5]) == 0x4F60 (你)")
expectEq(Int64(ascii[0]), 104, "Int64(ascii[0]) == 104 (h)")

// Rune round-trip: String(Rune) -> string
expectEq(String(cjk[1]), "好", "String(cjk[1]) == '好'")

// Emoji indexed character code point
expectEq(Int64(emoji[2]), 0x1F600, "Int64(emoji[2]) == 0x1F600 (😀)")

// --- Section: String for-in with UTF-8 ---
let chars = "你好"
var collected = ""
for (i in 0..chars.size) {
    collected = collected + String(chars[i])
}
expectEq(collected, "你好", "for-in UTF-8 chars")

// --- Section: Edge cases ---
let empty = ""
expectEq(empty.size, 0, "empty string .size")

let single_ascii = "A"
expectEq(single_ascii.size, 1, "single ASCII .size")
expectEq(single_ascii[0], r'A', "single ASCII index")

let single_cjk = "中"
expectEq(single_cjk.size, 1, "single CJK .size")
expectEq(single_cjk[0], r'中', "single CJK index")

let single_emoji = "🌍"
expectEq(single_emoji.size, 1, "single emoji .size")
expectEq(single_emoji[0], r'🌍', "single emoji index")

// --- Section: Interpolation with UTF-8 ---
let name = "仓颉"
let greeting = "Hello, ${name}!"
expectEq(greeting.size, 10, "interpolation UTF-8 .size")
expectEq(greeting[7], r'仓', "interpolation UTF-8 index 7")
expectEq(greeting[8], r'颉', "interpolation UTF-8 index 8")

// --- Section: String concatenation with UTF-8 ---
let concat = "你" + "好" + "世" + "界"
expectEq(concat.size, 4, "concat UTF-8 .size")
expectEq(concat, "你好世界", "concat UTF-8 equality")

if (!__test_failed) {
    println("PASS: 72_utf8_string")
}
