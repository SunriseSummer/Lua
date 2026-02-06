// Test: Implicit this in struct and class

// Struct with implicit this in init and methods
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
println("p1 = ${p1.toString()}")
println("p2 = ${p2.toString()}")
println("distance = ${p1.distanceTo(p2)}")

// Class with implicit this
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
println("count after 3 increments: ${c.getCount()}")
c.reset()
println("count after reset: ${c.getCount()}")

// Mix implicit and explicit this
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
println("area: ${r.area()}")
println("rect: ${r.toString()}")

// Class with string fields using implicit this
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
println(g.greet())

println("PASS: 12_implicit_this")
