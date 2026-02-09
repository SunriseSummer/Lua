dofile("cangjie-tests/_testing.cj")

// Test: Additional string edge cases and boundary tests
// Focus: boundary conditions, mixed encodings, comprehensive coverage

// --- Section: Multi-byte boundary indexing ---
// 2-byte: é (U+00E9), ñ (U+00F1)
// 3-byte: 你 (U+4F60), € (U+20AC)
// 4-byte: 😀 (U+1F600), 🎉 (U+1F389)
let allWidths = "aé€😀b"
expectEq(allWidths.size, 5, "mixed-width .size")
expectEq(allWidths[0], r'a', "1-byte char")
expectEq(allWidths[1], r'é', "2-byte char")
expectEq(allWidths[2], r'€', "3-byte char")
expectEq(allWidths[3], r'😀', "4-byte char")
expectEq(allWidths[4], r'b', "trailing 1-byte char")

// --- Section: Slice boundaries across byte widths ---
expectEq(allWidths[0..1], "a", "slice before 2-byte")
expectEq(allWidths[1..3], "é€", "slice 2-byte to 3-byte")
expectEq(allWidths[2..=4], "€😀b", "inclusive slice 3-byte to end")
expectEq(allWidths[0..=4], "aé€😀b", "full inclusive slice mixed")

// --- Section: String size edge cases ---
expectEq("".size, 0, "empty string size")
expectEq("a".size, 1, "single ASCII size")
expectEq("你".size, 1, "single 3-byte char size")
expectEq("😀".size, 1, "single 4-byte char size")
expectEq("é".size, 1, "single 2-byte char size")

// --- Section: Slice with equal start/end (empty result) ---
expectEq("hello"[3..3], "", "same start/end slice")
expectEq("你好世界"[2..2], "", "same CJK start/end slice")

// --- Section: Slice at string boundaries ---
expectEq("hello"[0..1], "h", "slice first char")
expectEq("hello"[4..=4], "o", "inclusive slice last char")
expectEq("你好世界"[0..1], "你", "slice first CJK char")
expectEq("你好世界"[3..=3], "界", "inclusive slice last CJK char")

// --- Section: Full-string slice ---
expectEq("hello"[0..=4], "hello", "full inclusive slice ASCII")
expectEq("你好世界"[0..=3], "你好世界", "full inclusive slice CJK")

// --- Section: IndexOf with various byte-width characters ---
let searchStr = "aé€😀bé"
expectEq(searchStr.indexOf("é"), 1, "indexOf 2-byte char")
expectEq(searchStr.indexOf("€"), 2, "indexOf 3-byte char")
expectEq(searchStr.indexOf("😀"), 3, "indexOf 4-byte char")
expectEq(searchStr.indexOf("b"), 4, "indexOf after 4-byte char")
expectEq(searchStr.indexOf("é", 2), 5, "indexOf 2-byte char with fromIndex")

// --- Section: LastIndexOf with multi-byte ---
expectEq(searchStr.lastIndexOf("é"), 5, "lastIndexOf 2-byte char")
expectEq(searchStr.lastIndexOf("a"), 0, "lastIndexOf first char")
expectEq(searchStr.lastIndexOf("x"), -1, "lastIndexOf not found")

// --- Section: Contains with multi-byte substrings ---
expectTrue("Hello你好World".contains("你好"), "contains multi-byte substring")
expectTrue("Hello你好World".contains("你好Wo"), "contains cross-boundary substring")
expectFalse("Hello".contains("你"), "not contains multi-byte in ASCII")

// --- Section: Replace with byte-width transitions ---
expectEq("a€b".replace("€", "X"), "aXb", "replace 3-byte with 1-byte")
expectEq("aXb".replace("X", "€"), "a€b", "replace 1-byte with 3-byte")
expectEq("😀😀".replace("😀", "!"), "!!", "replace 4-byte with 1-byte")

// --- Section: Split with multi-byte separator ---
let splitResult = "A你B你C".split("你")
expectEq(splitResult.size, 3, "split by 3-byte sep size")
expectEq(splitResult[0], "A", "split by CJK sep [0]")
expectEq(splitResult[1], "B", "split by CJK sep [1]")
expectEq(splitResult[2], "C", "split by CJK sep [2]")

// --- Section: Split into chars for multi-byte ---
let splitChars = "aé€".split("")
expectEq(splitChars.size, 3, "split multi-byte into chars size")
expectEq(splitChars[0], "a", "split multi-byte char 0")
expectEq(splitChars[1], "é", "split multi-byte char 1")
expectEq(splitChars[2], "€", "split multi-byte char 2")

// --- Section: Trim with adjacent multi-byte ---
expectEq("  你好  ".trim(), "你好", "trim spaces around CJK")
expectEq("\t\n😀\n\t".trim(), "😀", "trim whitespace around emoji")

// --- Section: StartsWith and EndsWith with multi-byte ---
expectTrue("😀hello".startsWith("😀"), "startsWith emoji")
expectTrue("hello😀".endsWith("😀"), "endsWith emoji")
expectFalse("hello😀".startsWith("😀"), "not startsWith wrong emoji pos")
expectTrue("café".startsWith("caf"), "startsWith partial multi-byte")
expectTrue("café".endsWith("fé"), "endsWith multi-byte suffix")

// --- Section: ToRuneArray for mixed byte widths ---
let runes = "aé€😀".toRuneArray()
expectEq(runes.size, 4, "toRuneArray mixed size")
expectEq(runes[0], r'a', "toRuneArray 1-byte")
expectEq(runes[1], r'é', "toRuneArray 2-byte")
expectEq(runes[2], r'€', "toRuneArray 3-byte")
expectEq(runes[3], r'😀', "toRuneArray 4-byte")

// --- Section: Concatenation preserves UTF-8 ---
let c1 = "Hello" + "你好"
let c2 = "Hello你好"
expectEq(c1, c2, "concat equals direct")
expectEq(c1.size, 7, "concat size")
expectEq(c1[5], r'你', "concat index into CJK")

// --- Section: String interpolation with multi-byte ---
let name = "café"
let msg = "I love ${name}!"
expectEq(msg.size, 12, "interpolation multi-byte size")
expectEq(msg[7], r'c', "interpolation index 7")
expectEq(msg[10], r'é', "interpolation index 10 (2-byte)")

// --- Section: Count with multi-byte ---
expectEq("你好你好你".count("你"), 3, "count 3-byte char")
expectEq("😀x😀y😀".count("😀"), 3, "count 4-byte char")
expectEq("abc".count(""), 4, "count empty in ASCII (n+1)")
expectEq("你好".count(""), 3, "count empty in CJK (n+1)")

// --- Section: toAsciiUpper/Lower with mixed content ---
expectEq("Hello你好".toAsciiUpper(), "HELLO你好", "upper with CJK preserved")
expectEq("Hello你好".toAsciiLower(), "hello你好", "lower with CJK preserved")

if (!__test_failed) {
    println("PASS: 78_string_edge_boundary")
}
