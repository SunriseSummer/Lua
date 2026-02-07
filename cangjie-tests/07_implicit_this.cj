dofile("cangjie-tests/_testing.cj")

// Test: Implicit this in struct and class
// Validates that struct/class methods can access fields without explicit 'this'.

// -- Section: Struct with implicit this --
struct Point {
  var x: Int64
  var y: Int64
  init(a: Int64, b: Int64) {
    x = a
    y = b
  }
  func toString(): String {
    return "(${x}, ${y})"
  }
  func distanceTo(other) {
    let dx = x - other.x
    let dy = y - other.y
    return (dx * dx + dy * dy) ** 0.5
  }
}

let p1 = Point(3, 4)
let p2 = Point(0, 0)
expectEq(p1.toString(), "(3, 4)", "p1.toString()")
expectEq(p2.toString(), "(0, 0)", "p2.toString()")
expectEq(p1.distanceTo(p2), 5.0, "distance")

// -- Section: Class with implicit this (Counter) --
class Counter {
  var count: Int64
  var step: Int64
  init(s: Int64) {
    count = 0
    step = s
  }
  func increment() {
    count = count + step
  }
  func getCount(): Int64 {
    return count
  }
  func reset() {
    count = 0
  }
}

let c = Counter(5)
c.increment()
c.increment()
c.increment()
expectEq(c.getCount(), 15, "count after 3 increments")
c.reset()
expectEq(c.getCount(), 0, "count after reset")

// -- Section: Mix implicit and explicit this (Rectangle) --
struct Rectangle {
  var width: Int64
  var height: Int64
  init(w: Int64, h: Int64) {
    width = w
    this.height = h
  }
  func area(): Int64 {
    return width * height
  }
  func toString(): String {
    return "${this.width}x${height}"
  }
}

let r = Rectangle(5, 3)
expectEq(r.area(), 15, "area")
expectEq(r.toString(), "5x3", "toString")

// -- Section: Class with string fields (Greeter) --
class Greeter {
  var greeting: String
  var target: String
  init(g: String, t: String) {
    greeting = g
    target = t
  }
  func greet(): String {
    return "${greeting}, ${target}!"
  }
}

let g = Greeter("Hello", "World")
expectEq(g.greet(), "Hello, World!", "greet")

if (!__test_failed) {
  println("PASS: 12_implicit_this")
}
