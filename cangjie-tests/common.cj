// Basic syntax coverage for Cangjie-style frontend

func add(a: Int, b: Int): Int {
  return a + b
}

let total: Int = add(2, 3)
if (total != 5) {
  error("function add failed")
}

/* collection literal */
let nums: Array<Int> = [1, 2, 3]
if (nums[1] != 1 || nums[2] != 2) {
  error("array literal failed")
}

var sum: Int = 0
for (i in 1..=3) {
  sum = sum + nums[i]
}
if (sum != 6) {
  error("for range failed")
}

var sum2: Int = 0
for (item in nums) {
  sum2 = sum2 + item
}
if (sum2 != 6) {
  error("for-in failed")
}

var idx: Int = 1
var accum: Int = 0
while (idx <= 3) {
  accum = accum + nums[idx]
  idx = idx + 1
}

var status: String = ""
if (accum > 10) {
  status = "big"
} else if (accum == 6) {
  status = "ok"
} else {
  status = "small"
}
if (status != "ok") {
  error("else-if failed")
}

if (!(false || false) && true) {
  // ok
} else {
  error("logical operators failed")
}

let nothing: Any = null
if (nothing != null) {
  error("null handling failed")
}

interface Greeter {
  func greet(): String
}

class Person <: Greeter {
  var name: String

  init(name: String) {
    this.name = name
  }

  func greet(): String {
    return this.name
  }
}

let person: Person = Person("Ada")
if (person.greet() != "Ada") {
  error("class method failed")
}

extend Person {
  func rename(newName: String) {
    this.name = newName
  }
}

person.rename("Bob")
if (person.greet() != "Bob") {
  error("extend method failed")
}

interface Movable {
  func move(dx: Int, dy: Int)
}

struct Point {
  var x: Int
  var y: Int

  init(x: Int, y: Int) {
    this.x = x
    this.y = y
  }

  func sum(): Int {
    return this.x + this.y
  }
}

extend Point <: Movable {
  func move(dx: Int, dy: Int) {
    this.x = this.x + dx
    this.y = this.y + dy
  }
}

let point: Point = Point(2, 3)
if (point.sum() != 5) {
  error("struct method failed")
}
point.move(1, 1)
if (point.sum() != 7) {
  error("extend interface failed")
}
