// Test: Named parameter calling syntax (name: value)
// Validates named params with defaults, lambda defaults, and mixed positional/named args

// --- Basic named parameter with default (refactored to return string) ---
func greet(name: String, prefix!: String = "Hello", suffix!: String = "!"): String {
    return "${prefix}, ${name}${suffix}"
}
var r = greet("World")
if (r != "Hello, World!") { println("FAIL: greet default expected 'Hello, World!', got '${r}'"); return () }
r = greet("World", prefix: "Hi")
if (r != "Hi, World!") { println("FAIL: greet prefix expected 'Hi, World!', got '${r}'"); return () }
r = greet("World", suffix: ".")
if (r != "Hello, World.") { println("FAIL: greet suffix expected 'Hello, World.', got '${r}'"); return () }
r = greet("World", prefix: "Hi", suffix: ".")
if (r != "Hi, World.") { println("FAIL: greet both expected 'Hi, World.', got '${r}'"); return () }

// --- Named parameter with all named args (no positional) ---
func point(x!: Int64 = 0, y!: Int64 = 0): String {
    return "(${x}, ${y})"
}
var p = point()
if (p != "(0, 0)") { println("FAIL: point() expected '(0, 0)', got '${p}'"); return () }
p = point(x: 3)
if (p != "(3, 0)") { println("FAIL: point(x:3) expected '(3, 0)', got '${p}'"); return () }
p = point(y: 4)
if (p != "(0, 4)") { println("FAIL: point(y:4) expected '(0, 4)', got '${p}'"); return () }
p = point(x: 3, y: 4)
if (p != "(3, 4)") { println("FAIL: point(x:3,y:4) expected '(3, 4)', got '${p}'"); return () }

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
if (treeResult != "CDBAFEG") { println("FAIL: tree expected 'CDBAFEG', got '${treeResult}'"); return () }

// --- Named params with mixed positional and named (refactored to return string) ---
func formatNum(value: Int64, prefix!: String = "", suffix!: String = ""): String {
    return "${prefix}${value}${suffix}"
}
var f = formatNum(42, prefix: "$", suffix: " USD")
if (f != "$42 USD") { println("FAIL: formatNum expected '$42 USD', got '${f}'"); return () }
f = formatNum(100, suffix: "%")
if (f != "100%") { println("FAIL: formatNum expected '100%', got '${f}'"); return () }
f = formatNum(42)
if (f != "42") { println("FAIL: formatNum expected '42', got '${f}'"); return () }

println("PASS: 18_named_params_call")
