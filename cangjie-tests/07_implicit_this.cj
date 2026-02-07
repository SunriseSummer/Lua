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
let r_p1 = p1.toString()
if (r_p1 != "(3, 4)") { println("FAIL: p1.toString() expected (3, 4), got ${r_p1}"); return () }
let r_p2 = p2.toString()
if (r_p2 != "(0, 0)") { println("FAIL: p2.toString() expected (0, 0), got ${r_p2}"); return () }
let r_dist = tostring(p1.distanceTo(p2))
if (r_dist != "5.0") { println("FAIL: distance expected 5.0, got ${r_dist}"); return () }

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
let r_count = c.getCount()
if (r_count != 15) { println("FAIL: count after 3 increments expected 15, got ${r_count}"); return () }
c.reset()
let r_reset = c.getCount()
if (r_reset != 0) { println("FAIL: count after reset expected 0, got ${r_reset}"); return () }

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
let r_area = r.area()
if (r_area != 15) { println("FAIL: area expected 15, got ${r_area}"); return () }
let r_rect = r.toString()
if (r_rect != "5x3") { println("FAIL: toString expected 5x3, got ${r_rect}"); return () }

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
let r_greet = g.greet()
if (r_greet != "Hello, World!") { println("FAIL: greet expected 'Hello, World!', got ${r_greet}"); return () }

println("PASS: 12_implicit_this")
