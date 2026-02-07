dofile("cangjie-tests/_testing.cj")

// Test: Class Inheritance and Polymorphism
// Validates single and multi-level inheritance, method overriding,
// polymorphic dispatch, and interface implementation on classes.

// -- Section: Base class --
class Animal {
  var name: String
  var sound: String
  init(name: String, sound: String) {
    this.name = name
    this.sound = sound
  }
  func speak(): String {
    return "${this.name} says ${this.sound}"
  }
  func getType(): String {
    return "Animal"
  }
}

// -- Section: Subclasses with inheritance --
class Dog <: Animal {
  var breed: String
  init(name: String, breed: String) {
    this.name = name
    this.sound = "Woof"
    this.breed = breed
  }
  // Override speak method (polymorphism)
  func speak(): String {
    return "${this.name} barks: ${this.sound}!"
  }
  func fetch(): String {
    return "${this.name} fetches the ball"
  }
}

class Cat <: Animal {
  init(name: String) {
    this.name = name
    this.sound = "Meow"
  }
  func speak(): String {
    return "${this.name} purrs: ${this.sound}"
  }
}

// -- Section: Basic inheritance assertions --
let a = Animal("Bird", "Tweet")
let d = Dog("Rex", "Labrador")
let c = Cat("Whiskers")

expectEq(a.speak(), "Bird says Tweet", "a.speak()")
expectEq(d.speak(), "Rex barks: Woof!", "d.speak()")
expectEq(c.speak(), "Whiskers purrs: Meow", "c.speak()")

// -- Section: Inherited methods --
expectEq(d.getType(), "Animal", "d.getType()")
expectEq(c.getType(), "Animal", "c.getType()")

// -- Section: Child-specific methods --
expectEq(d.fetch(), "Rex fetches the ball", "d.fetch()")

// -- Section: Polymorphic dispatch --
func makeSpeak(animal) {
  return animal.speak()
}

expectEq(makeSpeak(a), "Bird says Tweet", "makeSpeak(a)")
expectEq(makeSpeak(d), "Rex barks: Woof!", "makeSpeak(d)")
expectEq(makeSpeak(c), "Whiskers purrs: Meow", "makeSpeak(c)")

// -- Section: Multi-level inheritance --
class GuideDog <: Dog {
  var owner: String
  init(name: String, owner: String) {
    this.name = name
    this.sound = "Woof"
    this.breed = "Labrador"
    this.owner = owner
  }
  func guide(): String {
    return "${this.name} guides ${this.owner}"
  }
}

let gd = GuideDog("Buddy", "Alice")
expectEq(gd.speak(), "Buddy barks: Woof!", "gd.speak()")
expectEq(gd.getType(), "Animal", "gd.getType()")
expectEq(gd.fetch(), "Buddy fetches the ball", "gd.fetch()")
expectEq(gd.guide(), "Buddy guides Alice", "gd.guide()")

// -- Section: Class implementing interface --
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
    return "(${this.x}, ${this.y})"
  }
}

let p = Point(3, 4)
expectEq(p.toString(), "(3, 4)", "p.toString()")

if (!__test_failed) {
  println("PASS: 10_inheritance")
}
