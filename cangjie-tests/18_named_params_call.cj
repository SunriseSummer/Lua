// Test: Named parameter calling syntax (name: value)

// Basic named parameter with default
func greet(name: String, prefix!: String = "Hello", suffix!: String = "!") {
    println("${prefix}, ${name}${suffix}")
}
greet("World")
greet("World", prefix: "Hi")
greet("World", suffix: ".")
greet("World", prefix: "Hi", suffix: ".")

// Named parameter with all named args (no positional)
func point(x!: Int64 = 0, y!: Int64 = 0): String {
    return "(${x}, ${y})"
}
println("point() = ${point()}")
println("point(x: 3) = ${point(x: 3)}")
println("point(y: 4) = ${point(y: 4)}")
println("point(x: 3, y: 4) = ${point(x: 3, y: 4)}")

// Lambda as default value for named parameter
func node(value: String,
    left!: () -> Unit = {=>},
    right!: () -> Unit = {=>}) {
    return { =>
        left()
        print(value)
        right()
    }
}

// Build a binary tree using named params and closures
let tree = node("A",
    left: node("B", left: node("C", right: node("D"))),
    right: node("E", left: node("F"), right: node("G")))
tree()
println("")

// Named params with mixed positional and named
func formatNum(value: Int64, prefix!: String = "", suffix!: String = "") {
    println("${prefix}${value}${suffix}")
}
formatNum(42, prefix: "$", suffix: " USD")
formatNum(100, suffix: "%")
formatNum(42)

println("PASS: 18_named_params_call")
