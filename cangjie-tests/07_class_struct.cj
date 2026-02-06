// Test: Struct and Class

// Basic struct with member declarations, init, and this
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
    return (dx * dx + dy * dy) ^ 0.5
  }
}

// Constructor call syntax: Point(x, y)
let p1 = Point(3, 4)
let p2 = Point(0, 0)
println("p1 = ${p1.toString()}")
println("p2 = ${p2.toString()}")
println("distance = ${p1.distance(p2)}")

// Class with member declarations
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
println(dog.speak())
println(cat.speak())

// Interface (marker table)
interface Printable {
  func toString(): String
}

// Extend - add methods to existing types
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p3 = Point(1, 1)
let p4 = p3.translate(5, 10)
println("translated: ${p4.toString()}")

// Struct with generic type parameter
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
println("pair = ${pair.toString()}")

println("PASS: 07_struct_class")
