// Test interface default method implementations and operator overloading

// Interface with abstract method and default operator implementations
interface Printable {
    func describe(): String
    operator func +(other: Printable): String {
        return this.describe()
    }
}

// Interface with default method implementations
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
var ok = true
if (result.value() != 20) { ok = false }  // result is b2

// Test: extending built-in type with interface defaults
extend Float64 <: Chainable {
    func value(): Int64 {
        return Int64(this)
    }
}

// Test interface default func implementation
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
if (adder.compute(3) != 8) { ok = false }
// doubleCompute is inherited from interface default
if (adder.doubleCompute(3) != 16) { ok = false }

if (ok) {
    println("PASS: 33_interface_default")
} else {
    println("FAIL: 33_interface_default")
}
