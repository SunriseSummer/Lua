dofile("cangjie-tests/_testing.cj")

// Test: Interface default method implementations

// Interface with abstract method and default method
interface Calculator {
    func compute(x: Int64): Int64
    func doubleCompute(x: Int64): Int64 {
        return this.compute(x) * 2
    }
}

class Adder <: Calculator {
    Adder(let base: Int64) {}
    func compute(x: Int64): Int64 {
        return base + x
    }
}

let adder = Adder(5)
expectEq(adder.compute(3), 8, "adder.compute(3)")
// doubleCompute is inherited from interface default
expectEq(adder.doubleCompute(3), 16, "adder.doubleCompute(3)")

// Interface with default operator implementations
interface Chainable {
    func value(): Int64
    operator func >>(that: Chainable): Chainable {
        that << this
        that
    }
    operator func <<(that: Chainable): Chainable { this }
}

// Class implementing interface with default methods
class Box <: Chainable {
    var linked: ?Chainable = None
    Box(let val: Int64) {}
    func value(): Int64 {
        return val
    }
    operator func <<(that: Chainable): Chainable {
        linked = Some(that)
        this
    }
}

// Test: default >> operator uses << to chain
let b1 = Box(10)
let b2 = Box(20)
let result = b1 >> b2  // should call b2 << b1, then return b2
expectEq(result.value(), 20, "b1>>b2 returns b2")

// Class that overrides default method
class Multiplier <: Calculator {
    Multiplier(let factor: Int64) {}
    func compute(x: Int64): Int64 {
        return factor * x
    }
    func doubleCompute(x: Int64): Int64 {
        // Override the default: triple instead of double
        return this.compute(x) * 3
    }
}

let mul = Multiplier(4)
expectEq(mul.compute(5), 20, "mul.compute(5)")
expectEq(mul.doubleCompute(5), 60, "mul.doubleCompute(5) overridden")

// Interface with only abstract methods (no defaults)
interface Printable {
    func describe(): String
}

class Item <: Printable {
    Item(let name: String) {}
    func describe(): String {
        return "Item: ${name}"
    }
}

let item = Item("test")
expectEq(item.describe(), "Item: test", "item.describe()")

// Multiple interfaces with defaults
interface Describable {
    func info(): String {
        return "describable"
    }
}

class Widget <: Describable {
    Widget() {}
}

let w = Widget()
expectEq(w.info(), "describable", "Widget inherits default info()")

if (!__test_failed) {
    println("PASS: 33_interface_default")
}
