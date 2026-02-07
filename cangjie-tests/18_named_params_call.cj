dofile("cangjie-tests/_testing.cj")

// Test: Named parameter calling syntax (name: value)
// Validates named params with defaults, lambda defaults, and mixed positional/named args

// --- Basic named parameter with default (refactored to return string) ---
func greet(name: String, prefix!: String = "Hello", suffix!: String = "!"): String {
    return "${prefix}, ${name}${suffix}"
}
var r = greet("World")
expectEq(r, "Hello, World!", "greet default")
r = greet("World", prefix: "Hi")
expectEq(r, "Hi, World!", "greet prefix")
r = greet("World", suffix: ".")
expectEq(r, "Hello, World.", "greet suffix")
r = greet("World", prefix: "Hi", suffix: ".")
expectEq(r, "Hi, World.", "greet both")

// --- Named parameter with all named args (no positional) ---
func point(x!: Int64 = 0, y!: Int64 = 0): String {
    return "(${x}, ${y})"
}
var p = point()
expectEq(p, "(0, 0)", "point()")
p = point(x: 3)
expectEq(p, "(3, 0)", "point(x:3)")
p = point(y: 4)
expectEq(p, "(0, 4)", "point(y:4)")
p = point(x: 3, y: 4)
expectEq(p, "(3, 4)", "point(x:3,y:4)")

// --- Lambda as default value for named parameter (tree traversal) ---
var treeResult: String = ""
func node(value: String,
    left!: () -> Unit = {=>},
    right!: () -> Unit = {=>}) {
    return { =>
        left()
        treeResult = treeResult + value
        right()
    }
}

// Build a binary tree using named params and closures
let tree = node("A",
    left: node("B", left: node("C", right: node("D"))),
    right: node("E", left: node("F"), right: node("G")))
tree()
expectEq(treeResult, "CDBAFEG", "tree traversal")

// --- Named params with mixed positional and named (refactored to return string) ---
func formatNum(value: Int64, prefix!: String = "", suffix!: String = ""): String {
    return "${prefix}${value}${suffix}"
}
var f = formatNum(42, prefix: "$", suffix: " USD")
expectEq(f, "$42 USD", "formatNum $42 USD")
f = formatNum(100, suffix: "%")
expectEq(f, "100%", "formatNum 100%")
f = formatNum(42)
expectEq(f, "42", "formatNum 42")

if (!__test_failed) {
    println("PASS: 18_named_params_call")
}
