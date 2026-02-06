// Test: Struct and Class

// Basic struct with init constructor and this
struct Point {
  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
    return this
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

// Helper to create instances
func newPoint(x: Int64, y: Int64) {
  let p = setmetatable({}, Point)
  p:init(x, y)
  return p
}

let p1 = newPoint(3, 4)
let p2 = newPoint(0, 0)
println("p1 = ${p1:toString()}")        // (3, 4)
println("p2 = ${p2:toString()}")        // (0, 0)
println("distance = ${p1:distance(p2)}") // 5.0

// Class with init and this
class Animal {
  init(name: String, sound: String) {
    this.name = name
    this.sound = sound
    return this
  }
  func speak(): String {
    return "${this.name} says ${this.sound}!"
  }
}

func newAnimal(name: String, sound: String) {
  let a = setmetatable({}, Animal)
  a:init(name, sound)
  return a
}

let dog = newAnimal("Dog", "Woof")
let cat = newAnimal("Cat", "Meow")
println(dog:speak())  // Dog says Woof!
println(cat:speak())  // Cat says Meow!

// Interface (marker table)
interface Printable {
  func toString(): String
}

// Extend - add methods to existing types
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return newPoint(this.x + dx, this.y + dy)
  }
}

let p3 = newPoint(1, 1)
let p4 = p3:translate(5, 10)
println("translated: ${p4:toString()}")  // (6, 11)

// Struct with generic type parameter
struct Pair<T, U> {
  init(first, second) {
    this.first = first
    this.second = second
    return this
  }
  func toString(): String {
    return "(${tostring(this.first)}, ${tostring(this.second)})"
  }
}

func newPair(a, b) {
  let p = setmetatable({}, Pair)
  p:init(a, b)
  return p
}

let pair = newPair(1, "hello")
println("pair = ${pair:toString()}")  // (1, hello)

println("PASS: 07_struct_class")
