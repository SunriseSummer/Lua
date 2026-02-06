// Test: Interface-based Extension (extend A <: I { ... })

// Define interfaces
interface Printable {
  func toString(): String
}

interface Describable {
  func describe(): String
}

// Define a struct
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

// Extend Point with another interface
extend Point <: Describable {
  func describe(): String {
    return "Point at (${this.x}, ${this.y})"
  }
}

let p = Point(3, 4)
println("toString: ${p.toString()}")
println("describe: ${p.describe()}")

// Extend a class with interface
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
println("animal: ${a.toString()}")

// Extend built-in type Int64 with an interface
extend Int64 <: Printable {
  func double(): Int64 {
    return this * 2
  }
  func isPositive(): Bool {
    return this > 0
  }
}

let n = 42
println("double: ${n.double()}")
println("isPositive: ${n.isPositive()}")
println("negative isPositive: ${(-5).isPositive()}")

// Extend built-in type String with an interface
extend String <: Describable {
  func shout(): String {
    return this + "!!!"
  }
}

let s = "hello"
println("shout: ${s.shout()}")

// Extend without interface (existing feature should still work)
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p2 = p.translate(10, 20)
println("translated: ${p2.toString()}")

println("PASS: 11_extend_interface")
