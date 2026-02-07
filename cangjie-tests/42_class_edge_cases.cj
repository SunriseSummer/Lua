dofile("cangjie-tests/_testing.cj")

// Test: Class, struct, and inheritance edge cases

// --- Struct with no methods ---
struct Empty {
    var x: Int64
    init(x: Int64) { this.x = x }
}
let e = Empty(42)
expectEq(e.x, 42, "empty struct field")

// --- Class with multiple fields ---
class Point3D {
    var x: Float64
    var y: Float64
    var z: Float64
    init(x: Float64, y: Float64, z: Float64) {
        this.x = x
        this.y = y
        this.z = z
    }
    func magnitude(): Float64 {
        return (this.x ** 2 + this.y ** 2 + this.z ** 2) ** 0.5
    }
}
let p = Point3D(3.0, 4.0, 0.0)
expectEq(p.magnitude(), 5.0, "3D magnitude")

// --- Method chaining style (return this) ---
class Builder {
    var result: String
    init() { this.result = "" }
    func add(s: String) {
        this.result = this.result + s
    }
    func getResult(): String {
        return this.result
    }
}
let b = Builder()
b.add("Hello")
b.add(" ")
b.add("World")
expectEq(b.getResult(), "Hello World", "builder pattern")

// --- Class with default field values ---
class Config {
    var debug = false
    var name = "default"
    var count = 0
    Config() {}
}
let cfg = Config()
expectEq(cfg.debug, false, "default bool field")
expectEq(cfg.name, "default", "default string field")
expectEq(cfg.count, 0, "default int field")

// --- Deep inheritance chain (3 levels) ---
open class Base {
    var tag: String
    init(tag: String) { this.tag = tag }
    open func describe(): String { return "Base:${this.tag}" }
}

open class Mid <: Base {
    var extra: Int64
    init(tag: String, extra: Int64) {
        this.tag = tag
        this.extra = extra
    }
    open func describe(): String { return "Mid:${this.tag}:${this.extra}" }
}

class Leaf <: Mid {
    init(tag: String) {
        this.tag = tag
        this.extra = 99
    }
    func describe(): String { return "Leaf:${this.tag}" }
}

let leaf = Leaf("test")
expectEq(leaf.describe(), "Leaf:test", "deep inheritance override")
expectEq(leaf.extra, 99, "deep inheritance field")

// --- Polymorphic dispatch with array ---
let items: Array<Base> = [Base("a"), Mid("b", 1), Leaf("c")]
expectEq(items[0].describe(), "Base:a", "poly[0]")
expectEq(items[1].describe(), "Mid:b:1", "poly[1]")
expectEq(items[2].describe(), "Leaf:c", "poly[2]")

// --- Struct with extend ---
struct Counter {
    var n: Int64
    init(n: Int64) { this.n = n }
}
extend Counter {
    func next(): Int64 { return this.n + 1 }
    func prev(): Int64 { return this.n - 1 }
}
let c = Counter(10)
expectEq(c.next(), 11, "extend next()")
expectEq(c.prev(), 9, "extend prev()")

// --- Multiple interface implementation ---
interface HasName {
    func getName(): String
}
interface HasAge {
    func getAge(): Int64
}
class Person <: HasName & HasAge {
    var name: String
    var age: Int64
    init(name: String, age: Int64) {
        this.name = name
        this.age = age
    }
    func getName(): String { return this.name }
    func getAge(): Int64 { return this.age }
}
let person = Person("Alice", 30)
expectEq(person.getName(), "Alice", "multi iface name")
expectEq(person.getAge(), 30, "multi iface age")

// --- Static method ---
struct MathUtil {
    static func square(x: Int64): Int64 { return x * x }
    static func cube(x: Int64): Int64 { return x * x * x }
}
expectEq(MathUtil.square(5), 25, "static square")
expectEq(MathUtil.cube(3), 27, "static cube")

if (!__test_failed) {
    println("PASS: 42_class_edge_cases")
}
