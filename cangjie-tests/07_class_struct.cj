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

let p1 = Point(3, 4)
let p2 = Point(0, 0)
let r_p1 = p1.toString()
if (r_p1 != "(3, 4)") { println("FAIL: p1.toString() expected (3, 4), got ${r_p1}"); return () }
let r_p2 = p2.toString()
if (r_p2 != "(0, 0)") { println("FAIL: p2.toString() expected (0, 0), got ${r_p2}"); return () }
let r_dist = tostring(p1.distance(p2))
if (r_dist != "5.0") { println("FAIL: distance expected 5.0, got ${r_dist}"); return () }

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
let r_dog = dog.speak()
if (r_dog != "Dog says Woof!") { println("FAIL: dog.speak() expected 'Dog says Woof!', got ${r_dog}"); return () }
let r_cat = cat.speak()
if (r_cat != "Cat says Meow!") { println("FAIL: cat.speak() expected 'Cat says Meow!', got ${r_cat}"); return () }

// -- Section: Extend with translate method --
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p3 = Point(1, 1)
let p4 = p3.translate(5, 10)
let r_p4 = p4.toString()
if (r_p4 != "(6, 11)") { println("FAIL: translated point expected (6, 11), got ${r_p4}"); return () }

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
let r_pair = pair.toString()
if (r_pair != "(1, hello)") { println("FAIL: pair.toString() expected (1, hello), got ${r_pair}"); return () }

println("PASS: 07_struct_class")
