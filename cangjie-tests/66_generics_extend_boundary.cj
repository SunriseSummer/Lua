dofile("cangjie-tests/_testing.cj")

// Test: Generics and extend advanced edge cases

// --- Section: Generic function with multiple type params ---
func swapPair<T, U>(a: T, b: U) {
    return (b, a)
}
let swapped = swapPair(1, "hello")
expectEq(swapped[0], "hello", "swap first")
expectEq(swapped[1], 1, "swap second")

// --- Section: Generic struct with methods ---
struct Container<T> {
    var value: T
    init(v: T) { this.value = v }
    func get(): T { return this.value }
    func set(v: T) { this.value = v }
}

let intBox = Container(42)
expectEq(intBox.get(), 42, "Container<Int64> get")
intBox.set(100)
expectEq(intBox.get(), 100, "Container<Int64> set")

let strBox = Container("hello")
expectEq(strBox.get(), "hello", "Container<String> get")

// --- Section: Generic stack ---
struct GStack<T> {
    var items: Array<T>
    var count: Int64
    init() {
        this.items = {}
        this.count = 0
    }
    func push(item: T) {
        this.count = this.count + 1
        this.items[this.count] = item
    }
    func pop(): T {
        if (this.count == 0) { return nil }
        let item = this.items[this.count]
        this.count = this.count - 1
        return item
    }
    func peek(): T {
        if (this.count == 0) { return nil }
        return this.items[this.count]
    }
    func size(): Int64 { return this.count }
    func isEmpty(): Bool { return this.count == 0 }
}

let stack = GStack()
expectTrue(stack.isEmpty(), "stack empty initially")
stack.push(10)
stack.push(20)
stack.push(30)
expectEq(stack.size(), 3, "stack size after push")
expectEq(stack.peek(), 30, "stack peek top")
expectEq(stack.pop(), 30, "stack pop 30")
expectEq(stack.pop(), 20, "stack pop 20")
expectEq(stack.size(), 1, "stack size after pop")
expectFalse(stack.isEmpty(), "stack not empty")
expectEq(stack.pop(), 10, "stack pop 10")
expectTrue(stack.isEmpty(), "stack empty after all pops")

// --- Section: Extend on Int64 ---
extend Int64 {
    func isPositive(): Bool { return this > 0 }
    func isNegative(): Bool { return this < 0 }
    func isZero(): Bool { return this == 0 }
    func abs(): Int64 {
        if (this < 0) { return 0 - this }
        return this
    }
}

expectTrue(5.isPositive(), "5 is positive")
expectFalse(5.isNegative(), "5 not negative")
expectFalse(5.isZero(), "5 not zero")
expectTrue(0.isZero(), "0 is zero")
expectTrue((-3).isNegative(), "(-3) is negative")
expectEq((-5).abs(), 5, "abs(-5)")
expectEq(5.abs(), 5, "abs(5)")
expectEq(0.abs(), 0, "abs(0)")

// --- Section: Extend on String ---
extend String {
    func isEmpty(): Bool { return this.size == 0 }
    func startsWith(prefix: String): Bool {
        if (prefix.size > this.size) { return false }
        return this[0..prefix.size] == prefix
    }
    func endsWith(suffix: String): Bool {
        if (suffix.size > this.size) { return false }
        let start = this.size - suffix.size
        return this[start..this.size] == suffix
    }
}

expectTrue("".isEmpty(), "empty string isEmpty")
expectFalse("hello".isEmpty(), "hello not isEmpty")
expectTrue("hello world".startsWith("hello"), "startsWith hello")
expectFalse("hello world".startsWith("world"), "startsWith world false")
expectTrue("hello world".endsWith("world"), "endsWith world")
expectFalse("hello world".endsWith("hello"), "endsWith hello false")

// --- Section: Extend with operator ---
struct Vec2 {
    var x: Int64
    var y: Int64
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
}

extend Vec2 {
    operator func +(other: Vec2): Vec2 {
        return Vec2(this.x + other.x, this.y + other.y)
    }
    operator func ==(other: Vec2): Bool {
        return this.x == other.x && this.y == other.y
    }
    func toString(): String {
        return "(${this.x}, ${this.y})"
    }
}

let v1 = Vec2(1, 2)
let v2 = Vec2(3, 4)
let v3 = v1 + v2
expectEq(v3.toString(), "(4, 6)", "Vec2 add")
expectTrue(v3 == Vec2(4, 6), "Vec2 ==")

if (!__test_failed) {
    println("PASS: 66_generics_extend_boundary")
}
