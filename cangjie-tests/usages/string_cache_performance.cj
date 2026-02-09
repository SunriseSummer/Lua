dofile("cangjie-tests/_testing.cj")

// Usage: String cacheIndex for performance-sensitive scenarios
// Demonstrates cacheIndex() for O(1) random access on UTF-8 strings

// --- Scenario 1: Reverse a UTF-8 string efficiently ---
func reverseString(s: String): String {
    s.cacheIndex()  // Build offset table for O(1) access
    var result = ""
    var i = s.size - 1
    while (i >= 0) {
        result = result + s[i]
        i = i - 1
    }
    return result
}

expectEq(reverseString("hello"), "olleh", "reverse ASCII")
expectEq(reverseString("你好世界"), "界世好你", "reverse CJK")
expectEq(reverseString("Hi😀"), "😀iH", "reverse emoji")
expectEq(reverseString(""), "", "reverse empty")
expectEq(reverseString("X"), "X", "reverse single")

// --- Scenario 2: Extract every other character ---
func everyOther(s: String): String {
    s.cacheIndex()
    var result = ""
    var i = 0
    while (i < s.size) {
        result = result + s[i]
        i = i + 2
    }
    return result
}

expectEq(everyOther("abcdef"), "ace", "every other ASCII")
expectEq(everyOther("你好世界天地"), "你世天", "every other CJK")
expectEq(everyOther("a你b好c世"), "abc", "every other mixed")

// --- Scenario 3: Check if string is a rotation ---
func isRotation(s1: String, s2: String): Bool {
    if (s1.size != s2.size) { return false }
    if (s1.isEmpty()) { return true }
    let doubled = s1 + s1
    return doubled.contains(s2)
}

expectTrue(isRotation("abcde", "cdeab"), "rotation ASCII")
expectTrue(isRotation("你好世界", "世界你好"), "rotation CJK")
expectFalse(isRotation("abc", "acb"), "not rotation")
expectTrue(isRotation("", ""), "empty rotation")

// --- Scenario 4: Character frequency analysis ---
func charFrequency(s: String): String {
    s.cacheIndex()
    let runes = s.toRuneArray()
    var report = ""
    // Simple unique-char tracking via string search
    var seen = ""
    for (i in 0..runes.size) {
        let ch = runes[i]
        if (!seen.contains(ch)) {
            seen = seen + ch
            var count = 0
            for (j in 0..runes.size) {
                if (runes[j] == ch) {
                    count = count + 1
                }
            }
            if (report.size > 0) { report = report + "," }
            report = report + ch + ":" + tostring(count)
        }
    }
    return report
}

expectEq(charFrequency("aabbc"), "a:2,b:2,c:1", "char freq ASCII")
expectEq(charFrequency("你好你"), "你:2,好:1", "char freq CJK")

// --- Scenario 5: Substring extraction with cached index ---
func extractMiddle(s: String, start: Int64, length: Int64): String {
    s.cacheIndex()
    var end = start + length
    if (end > s.size) { end = s.size }
    if (start >= s.size || start < 0) { return "" }
    return s[start..end]
}

expectEq(extractMiddle("Hello World", 3, 5), "lo Wo", "extract middle ASCII")
expectEq(extractMiddle("你好世界天地人", 2, 3), "世界天", "extract middle CJK")
expectEq(extractMiddle("abc", 0, 100), "abc", "extract past end")
expectEq(extractMiddle("abc", 5, 2), "", "extract past string")

// --- Scenario 6: Build indexed character map ---
func charPositions(s: String, target: String): String {
    s.cacheIndex()
    var positions = ""
    for (i in 0..s.size) {
        if (s[i] == target) {
            if (positions.size > 0) { positions = positions + "," }
            positions = positions + tostring(i)
        }
    }
    return positions
}

expectEq(charPositions("hello world", "l"), "2,3,9", "positions of 'l'")
expectEq(charPositions("你好你好你", "你"), "0,2,4", "positions of 你")
expectEq(charPositions("abc", "x"), "", "positions not found")

if (!__test_failed) {
    println("PASS: usages/string_cache_performance")
}
