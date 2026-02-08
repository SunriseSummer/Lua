dofile("cangjie-tests/_testing.cj")

// Test: String and interpolation edge cases

// --- Empty string interpolation ---
let empty = ""
let s1 = "start${empty}end"
expectEq(s1, "startend", "empty interpolation")

// --- Nested interpolation with expressions ---
let a = 10
let b = 20
let s2 = "result: ${a + b * 2}"
expectEq(s2, "result: 50", "expr in interpolation")

// --- Interpolation with string variable ---
let name = "World"
let greeting = "Hello, " + name + "!"
let s3 = "${greeting}"
expectEq(s3, "Hello, World!", "string var in interpolation")

// --- Interpolation with boolean ---
let flag = true
let s4 = "flag is ${flag}"
expectEq(s4, "flag is true", "bool interpolation")

// --- Interpolation with nil ---
let n = nil
let s5 = "value is ${n}"
expectEq(s5, "value is nil", "nil interpolation")

// --- Multiple adjacent interpolations ---
let x = 1
let y = 2
let z = 3
let s6 = "${x}${y}${z}"
expectEq(s6, "123", "adjacent interpolations")

// --- Interpolation with method call ---
struct Greeter {
    var name: String
    init(name: String) {
        this.name = name
    }
    func greet(): String {
        return "Hi, ${this.name}!"
    }
}

let g = Greeter("Alice")
let s7 = "Says: ${g.greet()}"
expectEq(s7, "Says: Hi, Alice!", "method call in interpolation")

// --- Interpolation with array access ---
let arr = [10, 20, 30]
let s8 = "item: ${arr[1]}"
expectEq(s8, "item: 20", "array access in interpolation")

// --- String with special characters ---
let s9 = "tab:\there"
expectTrue(s9 != "tab:here", "tab in string")

let s10 = "newline:\n"
expectTrue(s10 != "newline:", "newline in string")

// --- String comparison ---
expectTrue("abc" == "abc", "string equality")
expectTrue("abc" != "def", "string inequality")
expectTrue("abc" < "abd", "string less than")
expectTrue("abc" < "b", "string ordering")

// --- String concatenation edge cases ---
let s11 = "" + "" + ""
expectEq(s11, "", "empty concat chain")

let s12 = "a" + "" + "b"
expectEq(s12, "ab", "concat with empty middle")

// --- tostring on various types ---
expectEq(tostring(3.14), "3.14", "tostring float")
expectEq(tostring(0.0), "0.0", "tostring 0.0")

// --- Interpolation with ternary-like if expression ---
let val = 42
let s13 = "is positive: ${val > 0}"
expectEq(s13, "is positive: true", "comparison in interpolation")

if (!__test_failed) {
    println("PASS: 41_string_edge_cases")
}
