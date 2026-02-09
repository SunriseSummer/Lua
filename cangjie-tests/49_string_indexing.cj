dofile("cangjie-tests/_testing.cj")

// Test: String indexing, slicing, and .size property

// --- Section: String .size ---
let s1 = "hello"
expectEq(s1.size, 5, "string .size basic")

let s2 = ""
expectEq(s2.size, 0, "empty string .size")

let s3 = "a"
expectEq(s3.size, 1, "single char string .size")

let s4 = "hello world"
expectEq(s4.size, 11, "string with space .size")

// --- Section: String indexing (0-based, returns Rune) ---
let s = "abcde"
expectEq(s[0], r'a', "string index 0")
expectEq(s[1], r'b', "string index 1")
expectEq(s[2], r'c', "string index 2")
expectEq(s[3], r'd', "string index 3")
expectEq(s[4], r'e', "string index 4")

// Index with variable
var idx = 2
expectEq(s[idx], r'c', "string index variable")

// Index computed from .size
expectEq(s[s.size - 1], r'e', "string index from size")

// --- Section: String indexing returns Rune type ---
expectTrue(type(s[0]) == "Rune", "string index returns Rune type")
expectTrue(s[0] == r'a', "string index == Rune literal")

// --- Section: String slicing (0-based, exclusive) ---
expectEq(s[0..3], "abc", "string slice 0..3 (exclusive)")
expectEq(s[1..4], "bcd", "string slice 1..4 (exclusive)")
expectEq(s[0..5], "abcde", "string slice full (exclusive)")
expectEq(s[2..2], "", "string slice empty (exclusive)")

// --- Section: String slicing (0-based, inclusive) ---
expectEq(s[0..=2], "abc", "string slice 0..=2 (inclusive)")
expectEq(s[1..=3], "bcd", "string slice 1..=3 (inclusive)")
expectEq(s[0..=4], "abcde", "string slice full (inclusive)")

// --- Section: String indexing with for loop ---
var chars = ""
for (i in 0..s.size) {
    chars = chars + String(s[i])
}
expectEq(chars, "abcde", "string for-in index loop")

// --- Section: String indexing with step ---
var everyOther = ""
for (i in 0..s.size:2) {
    everyOther = everyOther + String(s[i])
}
expectEq(everyOther, "ace", "string for-in step 2")

// --- Section: String methods still work ---
expectEq(string.upper(s), "ABCDE", "string method upper still works")
expectEq(string.sub(s, 1, 3), "abc", "string method sub still works")

if (!__test_failed) {
    println("PASS: 49_string_indexing")
}
