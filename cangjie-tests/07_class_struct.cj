dofile("cangjie-tests/_testing.cj")

// Test: Struct and Class
// Validates struct/class definitions, constructors, methods, extend blocks,
// and generic structs.

// -- Section: Basic struct with init and methods --
struct Point {
  var x: Int64
  var y: Int64
  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
  }
  func toString(): String {
    return "(${this.x}, ${this.y})"
  }
  func distance(other) {
    let dx = this.x - other.x
    let dy = this.y - other.y
    return (dx * dx + dy * dy) ** 0.5
  }
}

// Constructor call syntax: Point(x, y)
let p1 = Point(3, 4)
let p2 = Point(0, 0)
expectEq(p1.toString(), "(3, 4)", "p1.toString()")
expectEq(p2.toString(), "(0, 0)", "p2.toString()")
expectEq(p1.distance(p2), 5.0, "distance")

// -- Section: Class with member declarations --
class Animal {
  var name: String
  var sound: String
  init(name: String, sound: String) {
    this.name = name
    this.sound = sound
  }
  func speak(): String {
    return "${this.name} says ${this.sound}!"
  }
}

let dog = Animal("Dog", "Woof")
let cat = Animal("Cat", "Meow")
expectEq(dog.speak(), "Dog says Woof!", "dog.speak()")
expectEq(cat.speak(), "Cat says Meow!", "cat.speak()")

// -- Section: Extend with translate method --
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p3 = Point(1, 1)
let p4 = p3.translate(5, 10)
expectEq(p4.toString(), "(6, 11)", "translated point")

// -- Section: Generic struct Pair --
struct Pair<T, U> {
  var first: T
  var second: U
  init(first, second) {
    this.first = first
    this.second = second
  }
  func toString(): String {
    return "(${tostring(this.first)}, ${tostring(this.second)})"
  }
}

let pair = Pair(1, "hello")
expectEq(pair.toString(), "(1, hello)", "pair.toString()")

if (!__test_failed) {
  println("PASS: 07_struct_class")
}
