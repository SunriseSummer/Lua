dofile("cangjie-tests/_testing.cj")

// Usage: Shape hierarchy with polymorphism, interfaces, and extend

interface Printable {
    func toString(): String
}

interface HasArea {
    func area(): Float64
}

open class Shape <: Printable & HasArea {
    var name: String = "shape"
    open func area(): Float64 { return 0.0 }
    func toString(): String { return "${name}: area=${this.area()}" }
}

class Circle <: Shape {
    var radius: Float64
    init(r: Float64) {
        this.name = "Circle"
        this.radius = r
    }
    func area(): Float64 {
        return 3.14159265 * this.radius * this.radius
    }
}

class Rectangle <: Shape {
    var width: Float64
    var height: Float64
    init(w: Float64, h: Float64) {
        this.name = "Rectangle"
        this.width = w
        this.height = h
    }
    func area(): Float64 {
        return this.width * this.height
    }
}

class Triangle <: Shape {
    var base: Float64
    var height: Float64
    init(b: Float64, h: Float64) {
        this.name = "Triangle"
        this.base = b
        this.height = h
    }
    func area(): Float64 {
        return 0.5 * this.base * this.height
    }
}

// Test basic instances
let c = Circle(5.0)
let r = Rectangle(4.0, 6.0)
let t = Triangle(3.0, 8.0)

expectTrue(c.area() > 78.5 && c.area() < 78.6, "circle area ~78.54")
expectEq(r.area(), 24.0, "rectangle area 4*6")
expectEq(t.area(), 12.0, "triangle area 0.5*3*8")

// Test polymorphism via toString
expectTrue(string.find(c.toString(), "Circle", 1, true) != nil, "circle toString")
expectTrue(string.find(r.toString(), "Rectangle", 1, true) != nil, "rect toString")

// Test using extend to add utility methods
extend Circle {
    func diameter(): Float64 {
        return 2.0 * this.radius
    }
    func circumference(): Float64 {
        return 3.14159265 * this.diameter()
    }
}

expectEq(c.diameter(), 10.0, "circle diameter")
expectTrue(c.circumference() > 31.4 && c.circumference() < 31.5, "circle circumference ~31.4")

// Test with generic function
func describeShape(s: Shape): String {
    return "Shape '${s.name}' has area ${s.area()}"
}

let desc = describeShape(r)
expectTrue(string.find(desc, "Rectangle", 1, true) != nil, "describe rect name")
expectTrue(string.find(desc, "24.0", 1, true) != nil, "describe rect area")

// Find largest area
func largestArea(shapes: Array<Shape>): Float64 {
    var maxArea = 0.0
    for (s in shapes) {
        if (s.area() > maxArea) {
            maxArea = s.area()
        }
    }
    return maxArea
}

let shapes = [c, r, t]
let largest = largestArea(shapes)
expectTrue(largest > 78.5, "largest area is circle")

if (!__test_failed) {
    println("PASS: shape_hierarchy")
}
