dofile("cangjie-tests/_testing.cj")

// Usage: Fluent API with extend methods on literals
// Demonstrates practical use of calling extend methods directly on literals.

// -- Numeric utilities via extend --
extend Int64 {
    func abs(): Int64 {
        if (this < 0) { -this } else { this }
    }
    func clamp(lo: Int64, hi: Int64): Int64 {
        if (this < lo) { lo }
        else if (this > hi) { hi }
        else { this }
    }
    func even(): Bool {
        this % 2 == 0
    }
    func max(other: Int64): Int64 {
        if (this > other) { this } else { other }
    }
    func min(other: Int64): Int64 {
        if (this < other) { this } else { other }
    }
    func times(f: (Int64) -> Unit): Unit {
        var i = 0
        while (i < this) {
            f(i)
            i = i + 1
        }
    }
}

// -- String utilities via extend --
extend String {
    func repeat(n: Int64): String {
        var result = ""
        var i = 0
        while (i < n) {
            result = result + this
            i = i + 1
        }
        result
    }
    func padLeft(width: Int64, ch: String): String {
        var s = this
        while (s.size < width) {
            s = ch + s
        }
        s
    }
    func startsWith(prefix: String): Bool {
        if (prefix.size > this.size) { return false }
        string.sub(this, 1, prefix.size) == prefix
    }
}

// -- Section: Fluent number processing --
// Direct method chaining on literals
expectEq((-7).abs(), 7, "(-7).abs()")
expectEq(15.clamp(0, 10), 10, "15.clamp(0,10)")
expectEq((-5).clamp(0, 10), 0, "(-5).clamp(0,10)")
expectEq(5.clamp(0, 10), 5, "5.clamp(0,10)")
expectEq(3.max(7), 7, "3.max(7)")
expectEq(10.min(5), 5, "10.min(5)")

// Chained method calls on literal
expectEq((-15).abs().clamp(0, 10), 10, "(-15).abs().clamp(0,10)")

// Literal method call in loop (times pattern)
var counter = 0
3.times({ i: Int64 =>
    counter = counter + 1
})
expectEq(counter, 3, "3.times callback count")

// -- Section: String fluent API --
expectEq("ha".repeat(3), "hahaha", "\"ha\".repeat(3)")
expectEq("x".repeat(5), "xxxxx", "\"x\".repeat(5)")
expectEq("".repeat(100), "", "\"\".repeat(100)")
expectEq("42".padLeft(5, "0"), "00042", "\"42\".padLeft(5,\"0\")")
expectTrue("hello".startsWith("hel"), "\"hello\".startsWith(\"hel\")")
expectFalse("hello".startsWith("world"), "\"hello\".startsWith(\"world\")")
expectTrue("".startsWith(""), "\"\".startsWith(\"\")")

// -- Section: Combine literal methods in practical computation --
// Build a formatted table of squares
var table_str = ""
for (i in 1..6) {
    let num_str = tostring(i).padLeft(2, " ")
    let sq_str = tostring(i * i).padLeft(4, " ")
    table_str = table_str + num_str + ":" + sq_str + " "
}
expectEq(table_str, " 1:   1  2:   4  3:   9  4:  16  5:  25 ", "formatted table")

// -- Section: Literal methods in array processing --
let values = [(-3).abs(), 7.clamp(0, 5), 10.min(3)]
expectEq(values[0], 3, "array: (-3).abs()")
expectEq(values[1], 5, "array: 7.clamp(0,5)")
expectEq(values[2], 3, "array: 10.min(3)")
expectEq(values.size, 3, "values.size")

// Filter even numbers using literal method
let nums = [1, 2, 3, 4, 5, 6, 7, 8]
var even_sum = 0
for (n in nums) {
    if (n.even()) {
        even_sum = even_sum + n
    }
}
expectEq(even_sum, 20, "sum of evens via extend method")

if (!__test_failed) {
    println("PASS: extend_literal_fluent_api")
}
