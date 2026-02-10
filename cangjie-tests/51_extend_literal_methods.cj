dofile("cangjie-tests/_testing.cj")

// Test: Extend methods called directly on literal values
// Validates that extend methods work on Int64, Float64, String, Bool literals
// without requiring an intermediate variable.

// -- Section: Int64 literal method calls --
extend Int64 {
    func double(): Int64 {
        this * 2
    }
    func pow(e: Int64): Int64 {
        this ** e
    }
    func isEven(): Bool {
        this % 2 == 0
    }
    // Operator overloading in extend
    operator func -(other: Int64): Int64 {
        this - other
    }
}

let x = 2
expectEq(x.pow(10), 1024, "variable.pow(10)")
expectEq(2.pow(10), 1024, "2.pow(10)")
expectEq(0.pow(5), 0, "0.pow(5)")
expectEq(1.pow(100), 1, "1.pow(100)")
expectEq(3.double(), 6, "3.double()")
expectEq(0.double(), 0, "0.double()")
expectTrue(4.isEven(), "4.isEven()")
expectFalse(3.isEven(), "3.isEven()")
expectTrue(0.isEven(), "0.isEven()")

// Negative number in parens (unary minus is separate token)
expectEq((-5).pow(2), 25, "(-5).pow(2)")
expectEq((-1).double(), -2, "(-1).double()")

// -- Section: Float64 literal method calls --
extend Float64 {
    func half(): Float64 {
        this / 2.0
    }
    func isPositive(): Bool {
        this > 0.0
    }
}

expectEq(3.14.half(), 1.57, "3.14.half()")
expectEq(0.0.half(), 0.0, "0.0.half()")
expectEq(100.0.half(), 50.0, "100.0.half()")
expectTrue(1.5.isPositive(), "1.5.isPositive()")
expectFalse((-2.5).isPositive(), "(-2.5).isPositive()")

// -- Section: String literal method calls --
extend String {
    func shout(): String {
        this + "!!!"
    }
    func greet(): String {
        "Hello, " + this + "!"
    }
    func isEmpty(): Bool {
        this.size == 0
    }
}

let s = "world"
expectEq(s.shout(), "world!!!", "variable.shout()")
expectEq("world".shout(), "world!!!", "\"world\".shout()")
expectEq("hello".shout(), "hello!!!", "\"hello\".shout()")
expectEq("".shout(), "!!!", "\"\".shout()")
expectEq("Alice".greet(), "Hello, Alice!", "\"Alice\".greet()")
expectTrue("".isEmpty(), "\"\".isEmpty()")
expectFalse("abc".isEmpty(), "\"abc\".isEmpty()")

// -- Section: Bool literal method calls --
extend Bool {
    func toStr(): String {
        if (this) { "yes" } else { "no" }
    }
    func toggle(): Bool {
        !this
    }
}

let b = true
expectEq(b.toStr(), "yes", "variable.toStr()")
expectEq(true.toStr(), "yes", "true.toStr()")
expectEq(false.toStr(), "no", "false.toStr()")
expectTrue(false.toggle(), "false.toggle()")
expectFalse(true.toggle(), "true.toggle()")

// -- Section: Chained method calls on literals --
extend Int64 {
    func add(n: Int64): Int64 {
        this + n
    }
    // Method name starting with 'e' (exponent char for decimal mode)
    func even(): Bool {
        this % 2 == 0
    }
}

expectEq(5.add(3).double(), 16, "5.add(3).double()")
expectEq(1.add(1).add(1), 3, "1.add(1).add(1)")

// -- Section: Method name starting with 'e' (exponent-like) --
expectTrue(4.even(), "4.even()")
expectFalse(3.even(), "3.even()")
expectTrue(0.even(), "0.even()")

// -- Section: Extend methods used in expressions --
expectEq(2.pow(3) + 3.pow(2), 17, "2.pow(3) + 3.pow(2)")
expectTrue(10.isEven() && 4.isEven(), "10.isEven() && 4.isEven()")
expectFalse(3.isEven() || 5.isEven(), "3.isEven() || 5.isEven()")

// String method in expression
expectEq("a".shout() + "b".shout(), "a!!!b!!!", "concat shout results")

// -- Section: Literal method call in various contexts --
// In array constructor
let arr = [1.double(), 2.double(), 3.double()]
expectEq(arr[0], 2, "literal method in array[0]")
expectEq(arr[1], 4, "literal method in array[1]")
expectEq(arr[2], 6, "literal method in array[2]")

// In function arguments
func identity(n: Int64): Int64 { n }
expectEq(identity(7.double()), 14, "literal method as func arg")

// In if condition
expectTrue(if (2.even()) { true } else { false }, "literal method in if cond")

// Array literal .size
expectEq([1, 2, 3].size, 3, "[1,2,3].size")
expectEq([10, 20, 30, 40, 50].size, 5, "5-elem array literal .size")

// Array literal with index access
expectEq([10, 20, 30][1], 20, "array literal index")

// Statement-level literal method calls (void return)
"test".shout()   // should not error
true.toggle()    // should not error

// -- Section: Operator overloading in extend --
struct Vec2 {
    var x: Int64 = 0
    var y: Int64 = 0
}

extend Vec2 {
    operator func +(other: Vec2): Vec2 {
        Vec2(this.x + other.x, this.y + other.y)
    }
    operator func ==(other: Vec2): Bool {
        this.x == other.x && this.y == other.y
    }
    operator func -(other: Vec2): Vec2 {
        Vec2(this.x - other.x, this.y - other.y)
    }
    func toString(): String {
        "(${this.x}, ${this.y})"
    }
}

let v1 = Vec2(1, 2)
let v2 = Vec2(3, 4)
let v3 = v1 + v2
expectEq(v3.x, 4, "Vec2 + x")
expectEq(v3.y, 6, "Vec2 + y")

let v4 = v2 - v1
expectEq(v4.x, 2, "Vec2 - x")
expectEq(v4.y, 2, "Vec2 - y")

expectTrue(v1 == Vec2(1, 2), "Vec2 == true")
expectFalse(v1 == v2, "Vec2 == false")
expectEq(v3.toString(), "(4, 6)", "Vec2.toString()")

// Operator overload on extend with interface
interface Scalable {
    operator func *(scale: Int64): Vec2
}

extend Vec2 <: Scalable {
    operator func *(scale: Int64): Vec2 {
        Vec2(this.x * scale, this.y * scale)
    }
}

let v5 = Vec2(2, 3) * 5
expectEq(v5.x, 10, "Vec2 * scale x")
expectEq(v5.y, 15, "Vec2 * scale y")

// Chained operator calls
let v6 = Vec2(1, 1) + Vec2(2, 2) + Vec2(3, 3)
expectEq(v6.x, 6, "chained Vec2 + x")
expectEq(v6.y, 6, "chained Vec2 + y")

if (!__test_failed) {
    println("PASS: 51_extend_literal_methods")
}
