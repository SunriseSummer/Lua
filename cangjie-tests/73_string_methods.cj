dofile("cangjie-tests/_testing.cj")

// Test: String member methods (Cangjie-style)

// --- Section: isEmpty method ---
expectTrue("".isEmpty(), "empty string isEmpty()")
expectFalse("hello".isEmpty(), "non-empty string isEmpty()")
expectFalse(" ".isEmpty(), "space string isEmpty()")

// --- Section: contains ---
expectTrue("hello world".contains("world"), "contains 'world'")
expectTrue("hello world".contains("hello"), "contains 'hello'")
expectFalse("hello world".contains("xyz"), "not contains 'xyz'")
expectTrue("hello world".contains(""), "contains empty string")
expectTrue("你好世界".contains("好世"), "contains CJK")

// --- Section: startsWith ---
expectTrue("hello world".startsWith("hello"), "startsWith 'hello'")
expectFalse("hello world".startsWith("world"), "not startsWith 'world'")
expectTrue("hello".startsWith(""), "startsWith empty")
expectTrue("你好世界".startsWith("你好"), "startsWith CJK")

// --- Section: endsWith ---
expectTrue("hello world".endsWith("world"), "endsWith 'world'")
expectFalse("hello world".endsWith("hello"), "not endsWith 'hello'")
expectTrue("hello".endsWith(""), "endsWith empty")
expectTrue("你好世界".endsWith("世界"), "endsWith CJK")

// --- Section: replace ---
expectEq("hello world".replace("world", "cangjie"), "hello cangjie", "replace basic")
expectEq("aaa".replace("a", "bb"), "bbbbbb", "replace all occurrences")
expectEq("hello".replace("xyz", "abc"), "hello", "replace no match")
expectEq("你好世界".replace("世界", "仓颉"), "你好仓颉", "replace CJK")

// --- Section: split ---
let parts = "a,b,c".split(",")
expectEq(parts.size, 3, "split size")
expectEq(parts[0], "a", "split[0]")
expectEq(parts[1], "b", "split[1]")
expectEq(parts[2], "c", "split[2]")

let words = "hello world foo".split(" ")
expectEq(words.size, 3, "split by space size")
expectEq(words[0], "hello", "split word 0")
expectEq(words[2], "foo", "split word 2")

// Split into characters
let chars = "ABC".split("")
expectEq(chars.size, 3, "split '' into chars")
expectEq(chars[0], "A", "split char 0")
expectEq(chars[2], "C", "split char 2")

// Split CJK into characters
let cjkChars = "你好".split("")
expectEq(cjkChars.size, 2, "split CJK chars")
expectEq(cjkChars[0], "你", "split CJK char 0")
expectEq(cjkChars[1], "好", "split CJK char 1")

// --- Section: trim ---
expectEq("  hello  ".trim(), "hello", "trim spaces")
expectEq("\t\nhello\n\t".trim(), "hello", "trim whitespace")
expectEq("hello".trim(), "hello", "trim no change")
expectEq("".trim(), "", "trim empty")

// --- Section: trimStart / trimEnd ---
expectEq("  hello  ".trimStart(), "hello  ", "trimStart")
expectEq("  hello  ".trimEnd(), "  hello", "trimEnd")

// --- Section: toAsciiUpper / toAsciiLower ---
expectEq("hello".toAsciiUpper(), "HELLO", "toAsciiUpper")
expectEq("HELLO".toAsciiLower(), "hello", "toAsciiLower")
expectEq("Hello World".toAsciiUpper(), "HELLO WORLD", "toAsciiUpper mixed")
expectEq("Hello World".toAsciiLower(), "hello world", "toAsciiLower mixed")
expectEq("123!@#".toAsciiUpper(), "123!@#", "toAsciiUpper non-alpha")

// --- Section: indexOf ---
expectEq("hello world".indexOf("world"), 6, "indexOf basic")
expectEq("hello world".indexOf("xyz"), -1, "indexOf not found")
expectEq("hello world".indexOf("o"), 4, "indexOf single char")
expectEq("abcabc".indexOf("bc", 2), 4, "indexOf with fromIndex")
expectEq("你好世界".indexOf("世界"), 2, "indexOf CJK (char pos)")

// --- Section: lastIndexOf ---
expectEq("abcabc".lastIndexOf("bc"), 4, "lastIndexOf basic")
expectEq("hello".lastIndexOf("xyz"), -1, "lastIndexOf not found")
expectEq("abcabc".lastIndexOf("a"), 3, "lastIndexOf 'a'")

// --- Section: count ---
expectEq("hello".count("l"), 2, "count 'l' in hello")
expectEq("abcabc".count("abc"), 2, "count 'abc'")
expectEq("hello".count("xyz"), 0, "count not found")

// --- Section: toArray (bytes) ---
let bytes = "ABC".toArray()
expectEq(bytes.size, 3, "toArray ASCII size")
expectEq(bytes[0], 65, "toArray byte A")
expectEq(bytes[1], 66, "toArray byte B")
expectEq(bytes[2], 67, "toArray byte C")

// CJK bytes (UTF-8 encoded)
let cjkBytes = "你".toArray()
expectEq(cjkBytes.size, 3, "toArray CJK '你' has 3 bytes")

// --- Section: toRuneArray ---
let runes = "Hello你好".toRuneArray()
expectEq(runes.size, 7, "toRuneArray mixed size")
expectEq(runes[0], r'H', "toRuneArray[0]")
expectEq(runes[5], r'你', "toRuneArray[5]")
expectEq(runes[6], r'好', "toRuneArray[6]")

// --- Section: Method chaining ---
expectEq("  HELLO  ".trim().toAsciiLower(), "hello", "chain trim+lower")
expectTrue("Hello World".toAsciiLower().startsWith("hello"), "chain lower+startsWith")
expectEq("hello world".replace("hello", "hi").toAsciiUpper(), "HI WORLD", "chain replace+upper")

if (!__test_failed) {
    println("PASS: 73_string_methods")
}
