dofile("cangjie-tests/_testing.cj")

// Test: String operations usage - text processing

// --- Reverse a string ---
func reverseStr(s: String): String {
    var result = ""
    var i = s.size - 1
    while (i >= 0) {
        result = result + s[i]
        i = i - 1
    }
    return result
}

expectEq(reverseStr("hello"), "olleh", "reverse string")
expectEq(reverseStr(""), "", "reverse empty string")
expectEq(reverseStr("a"), "a", "reverse single char")

// --- Count character occurrences ---
func countChar(s: String, target: String): Int64 {
    var count: Int64 = 0
    for (i in 0..s.size) {
        if (s[i] == target) {
            count = count + 1
        }
    }
    return count
}

expectEq(countChar("hello world", "l"), 3, "count 'l' in hello world")
expectEq(countChar("aaa", "a"), 3, "count 'a' in aaa")
expectEq(countChar("abc", "x"), 0, "count 'x' in abc")

// --- Check if string is palindrome ---
func isPalindrome(s: String): Bool {
    var left = 0
    var right = s.size - 1
    while (left < right) {
        if (s[left] != s[right]) {
            return false
        }
        left = left + 1
        right = right - 1
    }
    return true
}

expectTrue(isPalindrome("abcba"), "palindrome abcba")
expectTrue(isPalindrome("abba"), "palindrome abba")
expectTrue(isPalindrome("a"), "palindrome single char")
expectTrue(isPalindrome(""), "palindrome empty")
expectFalse(isPalindrome("hello"), "not palindrome hello")

// --- Extract every nth character ---
func everyNth(s: String, n: Int64): String {
    var result = ""
    for (i in 0..s.size:n) {
        result = result + s[i]
    }
    return result
}

expectEq(everyNth("abcdefgh", 2), "aceg", "every 2nd char")
expectEq(everyNth("abcdefgh", 3), "adg", "every 3rd char")
expectEq(everyNth("abcdefgh", 1), "abcdefgh", "every 1st char")

// --- Slice and concatenate ---
let greeting = "Hello, World!"
let hello = greeting[0..5]
let world = greeting[7..12]
expectEq(hello, "Hello", "slice Hello")
expectEq(world, "World", "slice World")
expectEq(hello + " " + world, "Hello World", "slice concat")

// --- String size in conditional ---
func classify(s: String): String {
    if (s.size == 0) {
        return "empty"
    } else if (s.size <= 3) {
        return "short"
    } else if (s.size <= 10) {
        return "medium"
    } else {
        return "long"
    }
}

expectEq(classify(""), "empty", "classify empty")
expectEq(classify("hi"), "short", "classify short")
expectEq(classify("hello"), "medium", "classify medium")
expectEq(classify("hello world!"), "long", "classify long")

if (!__test_failed) {
    println("PASS: usages/string_processing")
}
