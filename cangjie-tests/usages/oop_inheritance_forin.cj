dofile("cangjie-tests/_testing.cj")

// Usage: OOP inheritance hierarchy with open classes, super(), and for-in
// Demonstrates a shape hierarchy with area calculations,
// polymorphic dispatch via arrays, and for-in iteration.

// -- Base shape class --
open class Shape {
    var name: String = "shape"
    open public func area(): Float64 {
        0.0
    }
    open public func describe(): String {
        "${name}: area=${area()}"
    }
}

// -- Circle extends Shape --
class Circle <: Shape {
    var radius: Float64 = 1.0
    init(radius: Float64) {
        this.name = "circle"
        this.radius = radius
    }
    public func area(): Float64 {
        3.14159265 * radius ** 2
    }
}

// -- Rectangle extends Shape --
class Rectangle <: Shape {
    var width: Float64 = 1.0
    var height: Float64 = 1.0
    init(width: Float64, height: Float64) {
        this.name = "rectangle"
        this.width = width
        this.height = height
    }
    public func area(): Float64 {
        width * height
    }
}

// -- Triangle extends Shape --
class Triangle <: Shape {
    var base: Float64 = 1.0
    var h: Float64 = 1.0
    init(base: Float64, h: Float64) {
        this.name = "triangle"
        this.base = base
        this.h = h
    }
    public func area(): Float64 {
        0.5 * base * h
    }
}

// -- Create shapes and use polymorphism --
let shapes = [Circle(5.0), Rectangle(4.0, 3.0), Triangle(6.0, 4.0)]

// Iterate with for-in and compute total area
var totalArea = 0.0
for (shape in shapes) {
    totalArea = totalArea + shape.area()
}

// Circle: pi * 25 = 78.5398..., Rectangle: 12, Triangle: 12
// Total ≈ 102.5398...
expectTrue(totalArea > 102.0, "total area > 102")
expectTrue(totalArea < 103.0, "total area < 103")

// -- Verify individual shapes --
let c = Circle(1.0)
expectTrue(c.area() > 3.14, "circle area > 3.14")
expectTrue(c.area() < 3.15, "circle area < 3.15")

let r = Rectangle(5.0, 3.0)
expectEq(r.area(), 15.0, "rectangle area")

let t = Triangle(10.0, 4.0)
expectEq(t.area(), 20.0, "triangle area")

// -- Verify describe uses polymorphic area --
expectTrue(string.find(c.describe(), "circle") != nil, "circle describe contains name")
expectTrue(string.find(r.describe(), "rectangle") != nil, "rectangle describe contains name")

// -- for-in with mixed polymorphic array --
var descriptions = ""
for (s in shapes) {
    descriptions = descriptions + s.name + ","
}
expectEq(descriptions, "circle,rectangle,triangle,", "shape names via for-in")

if (!__test_failed) {
    println("PASS: usages/oop_inheritance_forin")
}
