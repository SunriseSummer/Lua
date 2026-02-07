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

let r_a = a.speak()
if (r_a != "Bird says Tweet") { println("FAIL: a.speak() expected 'Bird says Tweet', got ${r_a}"); return () }
let r_d = d.speak()
if (r_d != "Rex barks: Woof!") { println("FAIL: d.speak() expected 'Rex barks: Woof!', got ${r_d}"); return () }
let r_c = c.speak()
if (r_c != "Whiskers purrs: Meow") { println("FAIL: c.speak() expected 'Whiskers purrs: Meow', got ${r_c}"); return () }

// -- Section: Inherited methods --
let r_dtype = d.getType()
if (r_dtype != "Animal") { println("FAIL: d.getType() expected 'Animal', got ${r_dtype}"); return () }
let r_ctype = c.getType()
if (r_ctype != "Animal") { println("FAIL: c.getType() expected 'Animal', got ${r_ctype}"); return () }

// -- Section: Child-specific methods --
let r_fetch = d.fetch()
if (r_fetch != "Rex fetches the ball") { println("FAIL: d.fetch() expected 'Rex fetches the ball', got ${r_fetch}"); return () }

// -- Section: Polymorphic dispatch --
func makeSpeak(animal) {
  return animal.speak()
}

let r_ma = makeSpeak(a)
if (r_ma != "Bird says Tweet") { println("FAIL: makeSpeak(a) expected 'Bird says Tweet', got ${r_ma}"); return () }
let r_md = makeSpeak(d)
if (r_md != "Rex barks: Woof!") { println("FAIL: makeSpeak(d) expected 'Rex barks: Woof!', got ${r_md}"); return () }
let r_mc = makeSpeak(c)
if (r_mc != "Whiskers purrs: Meow") { println("FAIL: makeSpeak(c) expected 'Whiskers purrs: Meow', got ${r_mc}"); return () }

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
let r_gdspeak = gd.speak()
if (r_gdspeak != "Buddy barks: Woof!") { println("FAIL: gd.speak() expected 'Buddy barks: Woof!', got ${r_gdspeak}"); return () }
let r_gdtype = gd.getType()
if (r_gdtype != "Animal") { println("FAIL: gd.getType() expected 'Animal', got ${r_gdtype}"); return () }
let r_gdfetch = gd.fetch()
if (r_gdfetch != "Buddy fetches the ball") { println("FAIL: gd.fetch() expected 'Buddy fetches the ball', got ${r_gdfetch}"); return () }
let r_gdguide = gd.guide()
if (r_gdguide != "Buddy guides Alice") { println("FAIL: gd.guide() expected 'Buddy guides Alice', got ${r_gdguide}"); return () }

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
let r_pts = p.toString()
if (r_pts != "(3, 4)") { println("FAIL: p.toString() expected '(3, 4)', got ${r_pts}"); return () }

println("PASS: 10_inheritance")
