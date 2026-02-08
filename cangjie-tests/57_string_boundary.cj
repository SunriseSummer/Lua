dofile("cangjie-tests/_testing.cj")

// Test: String operations boundary cases

// --- Section: Empty string operations ---
let empty = ""
expectEq(empty.size, 0, "empty string size")
expectEq(empty + "hello", "hello", "empty + hello")
expectEq("hello" + empty, "hello", "hello + empty")
expectEq(empty + empty, "", "empty + empty")

// --- Section: Single character string ---
let single = "x"
expectEq(single.size, 1, "single char size")
expectEq(single[0], "x", "single char indexing")

// --- Section: String interpolation edge cases ---
let val = 0
expectEq("${val}", "0", "interpolation of zero")
let boolVal = false
expectEq("${boolVal}", "false", "interpolation of false")

// --- Section: Nested interpolation ---
let a = 3
let b = 4
expectEq("result: ${a + b}", "result: 7", "interpolation with addition")
expectEq("${a} * ${b} = ${a * b}", "3 * 4 = 12", "multiple interpolations")

// --- Section: String concatenation with types ---
expectEq("num: " + tostring(42), "num: 42", "string + tostring(int)")
expectEq("pi: " + tostring(3.14), "pi: 3.14", "string + tostring(float)")

// --- Section: String comparison ---
expectTrue("abc" < "abd", "abc < abd")
expectTrue("abc" < "abcd", "abc < abcd (prefix)")
expectTrue("" < "a", "empty < a")
expectTrue("a" == "a", "a == a")
expectFalse("a" == "b", "a != b")
expectTrue("z" > "a", "z > a")

// --- Section: String slicing boundary ---
let s = "abcdef"
expectEq(s[0..1], "a", "slice first char")
expectEq(s[0..=0], "a", "inclusive slice first char")
expectEq(s[5..=5], "f", "inclusive slice last char")
expectEq(s[0..6], "abcdef", "slice entire string")
expectEq(s[0..=5], "abcdef", "inclusive slice entire string")
expectEq(s[2..4], "cd", "middle slice")

// --- Section: String with special characters in interpolation ---
let newline = "\n"
expectEq(newline.size, 1, "newline is 1 char")
let tab = "\t"
expectEq(tab.size, 1, "tab is 1 char")

// --- Section: String with escape sequences ---
let escaped = "hello\tworld\n"
expectTrue(escaped.size > 11, "escaped string has length > 11")

// --- Section: tostring edge cases ---
expectEq(tostring(nil), "nil", "tostring nil")
expectEq(tostring(true), "true", "tostring true")
expectEq(tostring(false), "false", "tostring false")
expectEq(tostring(0), "0", "tostring 0")
expectEq(tostring(-1), "-1", "tostring -1")

// --- Section: Repeated concatenation ---
var repeated = ""
for (i in 0..5) {
    repeated = repeated + "ab"
}
expectEq(repeated, "ababababab", "repeated concatenation")
expectEq(repeated.size, 10, "repeated concatenation size")

// --- Section: Interpolation with function call ---
func greet(name: String): String {
    return "Hi, ${name}!"
}
expectEq(greet("World"), "Hi, World!", "interpolation in function return")

// --- Section: String equality with interpolation ---
let name = "test"
expectTrue("test" == name, "string literal == variable")
expectTrue("${name}" == name, "interpolation == variable")
expectTrue("${name}" == "test", "interpolation == literal")

if (!__test_failed) {
    println("PASS: 57_string_boundary")
}
