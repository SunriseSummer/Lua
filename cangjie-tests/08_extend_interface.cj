dofile("cangjie-tests/_testing.cj")

// Test: Interface-based Extension (extend A <: I { ... })
// Validates extending structs/classes/built-in types with interface implementations.

// -- Section: Define interfaces --
interface Printable {
  func toString(): String
}

interface Describable {
  func describe(): String
}

// -- Section: Define and extend Point struct --
struct Point {
  var x: Int64
  var y: Int64
  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
  }
}

// Extend Point with Printable interface
extend Point <: Printable {
  func toString(): String {
    return "(${this.x}, ${this.y})"
  }
}

// Extend Point with Describable interface
extend Point <: Describable {
  func describe(): String {
    return "Point at (${this.x}, ${this.y})"
  }
}

let p = Point(3, 4)
expectEq(p.toString(), "(3, 4)", "p.toString()")
expectEq(p.describe(), "Point at (3, 4)", "p.describe()")

// -- Section: Extend class with interface --
class Animal {
  var name: String
  init(name: String) {
    this.name = name
  }
}

extend Animal <: Printable {
  func toString(): String {
    return "Animal(${this.name})"
  }
}

let a = Animal("Cat")
expectEq(a.toString(), "Animal(Cat)", "animal.toString()")

// -- Section: Extend built-in Int64 --
extend Int64 <: Printable {
  func double(): Int64 {
    return this * 2
  }
  func isPositive(): Bool {
    return this > 0
  }
}

let n = 42
expectEq(n.double(), 84, "n.double()")
expectTrue(n.isPositive(), "n.isPositive()")
expectFalse((-5).isPositive(), "(-5).isPositive()")

// -- Section: Extend built-in String --
extend String <: Describable {
  func shout(): String {
    return this + "!!!"
  }
}

let s = "hello"
expectEq(s.shout(), "hello!!!", "s.shout()")

// -- Section: Extend without interface --
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p2 = p.translate(10, 20)
expectEq(p2.toString(), "(13, 24)", "translated point")

if (!__test_failed) {
  println("PASS: 11_extend_interface")
}
