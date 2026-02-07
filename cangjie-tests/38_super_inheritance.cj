dofile("cangjie-tests/_testing.cj")

// Test: super() calls and advanced inheritance
// Validates super() in init to call parent constructor,
// inherited field resolution, and multi-level inheritance.

// -- Section: Basic super() call --
open class Animal {
    var name: String = ""
    var legs: Int64 = 0
    init(name: String, legs: Int64) {
        this.name = name
        this.legs = legs
    }
    open public func describe(): String {
        "${name} has ${legs} legs"
    }
}

class Dog <: Animal {
    var breed: String = "unknown"
    init(name: String, breed: String) {
        super(name, 4)
        this.breed = breed
    }
    public func describe(): String {
        "${name} (${breed}) has ${legs} legs"
    }
}

let d = Dog("Rex", "Labrador")
expectEq(d.name, "Rex", "Dog.name via super")
expectEq(d.legs, 4, "Dog.legs via super")
expectEq(d.breed, "Labrador", "Dog.breed")
expectEq(d.describe(), "Rex (Labrador) has 4 legs", "Dog.describe")

// -- Section: Multi-level super() --
class GuideDog <: Dog {
    var owner: String = ""
    init(name: String, breed: String, owner: String) {
        super(name, breed)
        this.owner = owner
    }
    public func describe(): String {
        "${name} guides ${owner}"
    }
}

let gd = GuideDog("Buddy", "Labrador", "Alice")
expectEq(gd.name, "Buddy", "GuideDog.name via multi-level super")
expectEq(gd.legs, 4, "GuideDog.legs via multi-level super")
expectEq(gd.breed, "Labrador", "GuideDog.breed via super")
expectEq(gd.owner, "Alice", "GuideDog.owner")
expectEq(gd.describe(), "Buddy guides Alice", "GuideDog.describe")

// -- Section: Primary constructor parent with super() --
open class Circle {
    Circle(var x: Int64, var y: Int64, var radius: Float64) {
        if (radius < 1.0) {
            this.radius = 1.0
        }
    }
    open public func info(): String {
        "${x}, ${y}, ${radius}"
    }
}

class Cylinder <: Circle {
    var height: Float64 = 1.0
    init(x: Int64, y: Int64, radius: Float64, height: Float64) {
        super(x, y, radius)
        this.height = height
        if (this.height < 1.0) {
            this.height = 1.0
        }
    }
    public func info(): String {
        "${x}, ${y}, ${radius}, ${height}"
    }
}

let c1 = Circle(0, 0, 1.0)
expectEq(c1.info(), "0, 0, 1.0", "Circle.info")

let c2 = Cylinder(1, 1, 2.0, 3.0)
expectEq(c2.info(), "1, 1, 2.0, 3.0", "Cylinder.info with super")

// radius < 1.0 should be clamped to 1.0
let c3 = Cylinder(0, 0, 0.5, 0.5)
expectEq(c3.info(), "0, 0, 1.0, 1.0", "Cylinder.info with clamped values")

// -- Section: Polymorphic dispatch with super-constructed objects --
func getInfo(obj) {
    return obj.info()
}

expectEq(getInfo(c1), "0, 0, 1.0", "polymorphic Circle.info")
expectEq(getInfo(c2), "1, 1, 2.0, 3.0", "polymorphic Cylinder.info")

if (!__test_failed) {
    println("PASS: 38_super_inheritance")
}
