dofile("cangjie-tests/_testing.cj")

// Test: Class, struct, inheritance, and interface interaction edge cases

// --- Section: Empty struct ---
struct Empty {
    init() {}
}
let e = Empty()
expectTrue(e != nil, "empty struct created")

// --- Section: Struct with only methods ---
struct Calculator {
    init() {}
    func add(a: Int64, b: Int64): Int64 { return a + b }
    func mul(a: Int64, b: Int64): Int64 { return a * b }
}
let calc = Calculator()
expectEq(calc.add(3, 4), 7, "struct method add")
expectEq(calc.mul(3, 4), 12, "struct method mul")

// --- Section: Class with default field values ---
class Config {
    var width: Int64 = 800
    var height: Int64 = 600
    var title: String = "Default"
}
let cfg = Config()
expectEq(cfg.width, 800, "class default field width")
expectEq(cfg.height, 600, "class default field height")
expectEq(cfg.title, "Default", "class default field title")

// --- Section: Class field mutation ---
cfg.width = 1024
cfg.title = "Changed"
expectEq(cfg.width, 1024, "mutated field width")
expectEq(cfg.title, "Changed", "mutated field title")

// --- Section: Interface with single method ---
interface Describable {
    func describe(): String
}

struct Point <: Describable {
    var x: Int64
    var y: Int64
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
    func describe(): String { return "(${this.x}, ${this.y})" }
}
let pt = Point(3, 4)
expectEq(pt.describe(), "(3, 4)", "interface method impl")

// --- Section: Multiple interface implementation ---
interface HasArea {
    func area(): Float64
}

interface HasPerimeter {
    func perimeter(): Float64
}

class Square <: HasArea & HasPerimeter {
    var side: Float64
    init(s: Float64) { this.side = s }
    func area(): Float64 { return this.side * this.side }
    func perimeter(): Float64 { return 4.0 * this.side }
}
let sq = Square(5.0)
expectEq(sq.area(), 25.0, "Square area")
expectEq(sq.perimeter(), 20.0, "Square perimeter")

// --- Section: Inheritance with method override ---
open class Vehicle {
    var name: String = "vehicle"
    open func type(): String { return "generic" }
}
class Car <: Vehicle {
    init() { this.name = "car" }
    func type(): String { return "sedan" }
}
class Truck <: Vehicle {
    init() { this.name = "truck" }
    func type(): String { return "heavy" }
}

let car = Car()
let truck = Truck()
expectEq(car.name, "car", "inherited field car")
expectEq(car.type(), "sedan", "overridden method car")
expectEq(truck.type(), "heavy", "overridden method truck")

// --- Section: Extend on struct ---
struct Vec2 {
    var x: Int64
    var y: Int64
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
}

extend Vec2 {
    func magnitude(): Float64 {
        return (Float64(this.x * this.x + this.y * this.y)) ** 0.5
    }
    func isOrigin(): Bool {
        return this.x == 0 && this.y == 0
    }
}

let v = Vec2(3, 4)
expectEq(v.magnitude(), 5.0, "extend method magnitude")
expectFalse(v.isOrigin(), "extend method isOrigin false")
let origin = Vec2(0, 0)
expectTrue(origin.isOrigin(), "extend method isOrigin true")

// --- Section: Static function ---
struct MathHelper {
    init() {}
    static func max(a: Int64, b: Int64): Int64 {
        if (a > b) { return a }
        return b
    }
    static func min(a: Int64, b: Int64): Int64 {
        if (a < b) { return a }
        return b
    }
}
expectEq(MathHelper.max(10, 20), 20, "static max")
expectEq(MathHelper.min(10, 20), 10, "static min")
expectEq(MathHelper.max(-5, -10), -5, "static max negative")

// --- Section: Operator overload on struct ---
struct Money {
    var amount: Int64
    init(a: Int64) { this.amount = a }
    operator func +(other: Money): Money {
        return Money(this.amount + other.amount)
    }
    operator func ==(other: Money): Bool {
        return this.amount == other.amount
    }
}
let m1 = Money(100)
let m2 = Money(200)
let m3 = m1 + m2
expectEq(m3.amount, 300, "operator + on struct")
expectTrue(m3 == Money(300), "operator == on struct")
expectFalse(m1 == m2, "operator == false")

// --- Section: this implicit access ---
struct Counter {
    var count: Int64
    init() { count = 0 }
    func increment() { count = count + 1 }
    func getCount(): Int64 { return count }
}
let ctr = Counter()
ctr.increment()
ctr.increment()
ctr.increment()
expectEq(ctr.getCount(), 3, "implicit this access")

if (!__test_failed) {
    println("PASS: 59_class_struct_boundary")
}
