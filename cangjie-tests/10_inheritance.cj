// Test: Class Inheritance and Polymorphism

// Base class
class Animal {
  var name: String
  var sound: String
  init(name: String, sound: String) {
    this.name = name
    this.sound = sound
  }
  func speak(): String {
    return this.name .. " says " .. this.sound
  }
  func getType(): String {
    return "Animal"
  }
}

// Subclass with <: inheritance syntax
class Dog <: Animal {
  var breed: String
  init(name: String, breed: String) {
    this.name = name
    this.sound = "Woof"
    this.breed = breed
  }
  // Override speak method (polymorphism)
  func speak(): String {
    return this.name .. " barks: " .. this.sound .. "!"
  }
  func fetch(): String {
    return this.name .. " fetches the ball"
  }
}

class Cat <: Animal {
  init(name: String) {
    this.name = name
    this.sound = "Meow"
  }
  func speak(): String {
    return this.name .. " purrs: " .. this.sound
  }
}

// Test basic inheritance
let a = Animal("Bird", "Tweet")
let d = Dog("Rex", "Labrador")
let c = Cat("Whiskers")

println(a.speak())
println(d.speak())
println(c.speak())

// Test inherited methods
println(d.getType())
println(c.getType())

// Test child-specific methods
println(d.fetch())

// Test polymorphism: parent reference calling overridden method
// In this dynamic implementation, the method dispatch is always dynamic
func makeSpeak(animal) {
  return animal.speak()
}

println(makeSpeak(a))
println(makeSpeak(d))
println(makeSpeak(c))

// Multi-level inheritance
class GuideDog <: Dog {
  var owner: String
  init(name: String, owner: String) {
    this.name = name
    this.sound = "Woof"
    this.breed = "Labrador"
    this.owner = owner
  }
  func guide(): String {
    return this.name .. " guides " .. this.owner
  }
}

let gd = GuideDog("Buddy", "Alice")
println(gd.speak())
println(gd.getType())
println(gd.fetch())
println(gd.guide())

// Class implementing interface
interface Printable {
  func toString(): String
}

class Point <: Printable {
  var x: Int64
  var y: Int64
  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
  }
  func toString(): String {
    return "(" .. tostring(this.x) .. ", " .. tostring(this.y) .. ")"
  }
}

let p = Point(3, 4)
println(p.toString())

println("PASS: 10_inheritance")
