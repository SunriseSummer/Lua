dofile("cangjie-tests/_testing.cj")

// Usage: Comprehensive UTF-8 string processing showcase
// Demonstrates real-world patterns with UTF-8 native string support

// --- CSV parsing with Unicode data ---
let csv = "名前,年齢,都市\n张三,25,北京\n李四,30,上海"
let lines = csv.split("\n")
expectEq(lines.size, 3, "CSV line count")

let header = lines[0].split(",")
expectEq(header[0], "名前", "CSV header 0")
expectEq(header[1], "年齢", "CSV header 1")
expectEq(header[2], "都市", "CSV header 2")

let row1 = lines[1].split(",")
expectEq(row1[0], "张三", "CSV row1 name")
expectEq(row1[1], "25", "CSV row1 age")
expectEq(row1[2], "北京", "CSV row1 city")

// --- String builder pattern ---
var result = ""
let words = ["Hello", "你好", "World", "世界"]
for (i in 0..words.size) {
    if (i > 0) {
        result = result + " "
    }
    result = result + words[i]
}
expectEq(result, "Hello 你好 World 世界", "string builder")

// --- Text search and replace ---
let tmpl = "Dear NAME, welcome to PLACE!"
let personalized = tmpl.replace("NAME", "仓颉").replace("PLACE", "MoonCangjie")
expectEq(personalized, "Dear 仓颉, welcome to MoonCangjie!", "template replace")

// --- Character-level iteration ---
let text = "A中B"
var charList = ""
for (i in 0..text.size) {
    charList = charList + "[" + text[i] + "]"
}
expectEq(charList, "[A][中][B]", "char iteration brackets")

// --- Palindrome check with UTF-8 ---
func isPalindrome(s: String): Bool {
    let runes = s.toRuneArray()
    var left = 0
    var right = runes.size - 1
    while (left < right) {
        if (runes[left] != runes[right]) {
            return false
        }
        left = left + 1
        right = right - 1
    }
    return true
}

expectTrue(isPalindrome("aba"), "aba is palindrome")
expectTrue(isPalindrome("上下下上"), "上下下上 is palindrome")
expectFalse(isPalindrome("hello"), "hello not palindrome")
expectTrue(isPalindrome(""), "empty is palindrome")
expectTrue(isPalindrome("a"), "single char is palindrome")

// --- Word frequency (simple) ---
func countWord(text: String, word: String): Int64 {
    return text.count(word)
}

let article = "the cat sat on the mat the cat"
expectEq(countWord(article, "the"), 3, "count 'the'")
expectEq(countWord(article, "cat"), 2, "count 'cat'")
expectEq(countWord(article, "dog"), 0, "count 'dog'")

// --- String validation ---
func isNumericString(s: String): Bool {
    if (s.isEmpty) { return false }
    for (i in 0..s.size) {
        let c = s[i]
        if (c < "0" || c > "9") {
            return false
        }
    }
    return true
}

expectTrue(isNumericString("12345"), "12345 is numeric")
expectFalse(isNumericString("123a5"), "123a5 is not numeric")
expectFalse(isNumericString(""), "empty not numeric")

// --- Byte-level and character-level interplay ---
let multibyte = "café"
let byteLen = multibyte.toArray().size
let charLen = multibyte.size
expectTrue(byteLen > charLen, "byte len > char len for multibyte")
expectEq(charLen, 4, "café has 4 chars")

// Round-trip test
let restored = __cangjie_string_from_byte_array(multibyte.toArray())
expectEq(restored, multibyte, "multibyte round-trip")

if (!__test_failed) {
    println("PASS: usages/utf8_string_processing")
}
