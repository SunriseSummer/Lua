// Test: Struct and Class

// Basic struct
struct Point {
  func new(x, y) {
    self.x = x
    self.y = y
    return self
  }
  func toString() {
    return "(${self.x}, ${self.y})"
  }
  func distance(other) {
    let dx = self.x - other.x
    let dy = self.y - other.y
    return (dx * dx + dy * dy) ^ 0.5
  }
}

// Helper to create instances
func newPoint(x, y) {
  let p = setmetatable({}, Point)
  p:new(x, y)
  return p
}

let p1 = newPoint(3, 4)
let p2 = newPoint(0, 0)
println("p1 = ${p1:toString()}")        // (3, 4)
println("p2 = ${p2:toString()}")        // (0, 0)
println("distance = ${p1:distance(p2)}") // 5.0

// Class with more features
class Animal {
  func new(name, sound) {
    self.name = name
    self.sound = sound
    return self
  }
  func speak() {
    return "${self.name} says ${self.sound}!"
  }
}

func newAnimal(name, sound) {
  let a = setmetatable({}, Animal)
  a:new(name, sound)
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
  func translate(dx, dy) {
    return newPoint(self.x + dx, self.y + dy)
  }
}

let p3 = newPoint(1, 1)
let p4 = p3:translate(5, 10)
println("translated: ${p4:toString()}")  // (6, 11)

// Struct with generic-like pattern (using type name in <>)
struct Pair {
  func new(first, second) {
    self.first = first
    self.second = second
    return self
  }
  func toString() {
    return "(${tostring(self.first)}, ${tostring(self.second)})"
  }
}

func newPair(a, b) {
  let p = setmetatable({}, Pair)
  p:new(a, b)
  return p
}

let pair = newPair(1, "hello")
println("pair = ${pair:toString()}")  // (1, hello)

println("PASS: 07_struct_class")
