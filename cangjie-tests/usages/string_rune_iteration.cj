dofile("cangjie-tests/_testing.cj")

// Usage: Comprehensive string Rune operations and for-in iteration

// --- Scenario 1: Classify characters in a string ---
func classifyChars(s: String): String {
    var digits = 0
    var letters = 0
    var other = 0
    for (ch in s) {
        if (ch >= r'0' && ch <= r'9') {
            digits = digits + 1
        } else if ((ch >= r'a' && ch <= r'z') || (ch >= r'A' && ch <= r'Z')) {
            letters = letters + 1
        } else {
            other = other + 1
        }
    }
    return "letters:${letters},digits:${digits},other:${other}"
}

expectEq(classifyChars("Hello123!"), "letters:5,digits:3,other:1", "classify mixed chars")
expectEq(classifyChars(""), "letters:0,digits:0,other:0", "classify empty string")
expectEq(classifyChars("ABC"), "letters:3,digits:0,other:0", "classify letters only")
expectEq(classifyChars("你好"), "letters:0,digits:0,other:2", "classify CJK as other")

// --- Scenario 2: Caesar cipher with Rune arithmetic ---
func caesarEncrypt(s: String, shift: Int64): String {
    var result = ""
    for (ch in s) {
        if (ch >= r'a' && ch <= r'z') {
            let shifted = (Int64(ch) - Int64(r'a') + shift) % 26 + Int64(r'a')
            result = result + String(Rune(shifted))
        } else if (ch >= r'A' && ch <= r'Z') {
            let shifted = (Int64(ch) - Int64(r'A') + shift) % 26 + Int64(r'A')
            result = result + String(Rune(shifted))
        } else {
            result = result + String(ch)
        }
    }
    return result
}

expectEq(caesarEncrypt("abc", 1), "bcd", "caesar shift 1")
expectEq(caesarEncrypt("xyz", 3), "abc", "caesar wrap around")
expectEq(caesarEncrypt("Hello!", 13), "Uryyb!", "ROT13 encrypt")
expectEq(caesarEncrypt("Uryyb!", 13), "Hello!", "ROT13 decrypt (self-inverse)")

// --- Scenario 3: Reverse string using for-in Rune iteration ---
func reverseViaForIn(s: String): String {
    var result = ""
    for (ch in s) {
        result = String(ch) + result
    }
    return result
}

expectEq(reverseViaForIn("hello"), "olleh", "reverse via for-in")
expectEq(reverseViaForIn("你好世界"), "界世好你", "reverse CJK via for-in")
expectEq(reverseViaForIn("A😀B"), "B😀A", "reverse mixed via for-in")
expectEq(reverseViaForIn(""), "", "reverse empty via for-in")

// --- Scenario 4: Count unique characters using for-in ---
func countUnique(s: String): Int64 {
    var seen = ""
    var count = 0
    for (ch in s) {
        let chStr = String(ch)
        if (!seen.contains(chStr)) {
            seen = seen + chStr
            count = count + 1
        }
    }
    return count
}

expectEq(countUnique("hello"), 4, "unique chars in hello")
expectEq(countUnique("aaa"), 1, "unique chars in aaa")
expectEq(countUnique("abcabc"), 3, "unique chars in abcabc")
expectEq(countUnique("你好你"), 2, "unique CJK chars")
expectEq(countUnique(""), 0, "unique chars in empty")

// --- Scenario 5: String → Array<Byte> → String round-trip in processing ---
func toUpperBytes(s: String): String {
    let bytes = s.toArray()
    for (i in 0..bytes.size) {
        let b = bytes[i]
        if (b >= 97 && b <= 122) {
            bytes[i] = b - 32
        }
    }
    return String(bytes)
}

expectEq(toUpperBytes("hello"), "HELLO", "uppercase via bytes")
expectEq(toUpperBytes("Hello World"), "HELLO WORLD", "mixed case via bytes")
expectEq(toUpperBytes("123"), "123", "digits unchanged via bytes")

// --- Scenario 6: Build string from Rune code points ---
func buildFromCodepoints(cps: Array<Int64>): String {
    var result = ""
    for (i in 0..cps.size) {
        result = result + String(Rune(cps[i]))
    }
    return result
}

let cps: Array<Int64> = [72, 101, 108, 108, 111]
expectEq(buildFromCodepoints(cps), "Hello", "build Hello from code points")

let cjkCps: Array<Int64> = [0x4F60, 0x597D]
expectEq(buildFromCodepoints(cjkCps), "你好", "build CJK from code points")

// --- Scenario 7: toRuneArray values match for-in iteration ---
let testStr = "Hi你😀"
let runeArr = testStr.toRuneArray()
var forInCount = 0
var forInMatch = true
for (ch in testStr) {
    if (ch != runeArr[forInCount]) {
        forInMatch = false
    }
    forInCount = forInCount + 1
}
expectEq(runeArr.size, forInCount, "toRuneArray size == for-in count")
expectTrue(forInMatch, "toRuneArray values match for-in values")

if (!__test_failed) {
    println("PASS: usages/string_rune_iteration")
}
