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

extend Point <: Printable {
  func toString(): String {
    return "(${this.x}, ${this.y})"
  }
}

extend Point <: Describable {
  func describe(): String {
    return "Point at (${this.x}, ${this.y})"
  }
}

let p = Point(3, 4)
let r_pts = p.toString()
if (r_pts != "(3, 4)") { println("FAIL: p.toString() expected (3, 4), got ${r_pts}"); return () }
let r_pdesc = p.describe()
if (r_pdesc != "Point at (3, 4)") { println("FAIL: p.describe() expected 'Point at (3, 4)', got ${r_pdesc}"); return () }

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
let r_animal = a.toString()
if (r_animal != "Animal(Cat)") { println("FAIL: animal.toString() expected 'Animal(Cat)', got ${r_animal}"); return () }

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
let r_dbl = n.double()
if (r_dbl != 84) { println("FAIL: n.double() expected 84, got ${r_dbl}"); return () }
let r_pos = n.isPositive()
if (r_pos != true) { println("FAIL: n.isPositive() expected true, got ${r_pos}"); return () }
let r_neg = (-5).isPositive()
if (r_neg != false) { println("FAIL: (-5).isPositive() expected false, got ${r_neg}"); return () }

// -- Section: Extend built-in String --
extend String <: Describable {
  func shout(): String {
    return this + "!!!"
  }
}

let s = "hello"
let r_shout = s.shout()
if (r_shout != "hello!!!") { println("FAIL: s.shout() expected 'hello!!!', got ${r_shout}"); return () }

// -- Section: Extend without interface --
extend Point {
  func translate(dx: Int64, dy: Int64) {
    return Point(this.x + dx, this.y + dy)
  }
}

let p2 = p.translate(10, 20)
let r_trans = p2.toString()
if (r_trans != "(13, 24)") { println("FAIL: translated point expected (13, 24), got ${r_trans}"); return () }

println("PASS: 11_extend_interface")
