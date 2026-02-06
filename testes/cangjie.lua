/*
  basic syntax coverage for Cangjie-style Lua
  (block comment span coverage)
*/
let greeting: String = "hello"
var counter: Int = 0 // line comment after code
let maybe: Int = null
assert(maybe == nil)

func add(a: Int, b: Int): Int {
  return a + b
}

let arr: Array<Int> = [1, 2, 3]
assert(#arr == 3)
assert(arr[2] == 2)

let ages: Map<String, Int> = {"alice": 30, "bob": 25}
assert(ages["bob"] == 25)

let setValues = {1, 2, 3}
var set = {}
for (value in ipairs(setValues)) {
  set[value] = true
}
assert(set[3] == true)

let doubler = func (value: Int): Int {
  return value * 2
}
assert(doubler(4) == 8)
assert(!false)

var sum = 0
for (i in 1..=3) {
  sum = sum + i
}

let span = 2..5
var spanSum = 0
for (i in span) {
  spanSum = spanSum + i
}
var descendingSum = 0
for (i in 3..1) {
  descendingSum = descendingSum + i
}

while (sum < 10 && counter != 2) {
  counter = counter + 1
  if (counter == 1 || sum == 6) {
    sum = sum + 1
  } else if (counter == 2) {
    sum = sum + 2
  }
}

assert(spanSum == 9)
assert(descendingSum == 5)
assert(add(sum, counter) == 11)
assert(doubler(sum) == 18)

struct Point {
  var x: Int = 0
  var y: Int = 0

  func move(dx: Int, dy: Int) {
    this.x = this.x + dx
    this.y = this.y + dy
  }

  func sum(): Int {
    return this.x + this.y
  }
}

class Counter {
  var value: Int = 0

  init(start: Int) {
    this.value = start
  }

  func inc() {
    this.value = this.value + 1
  }
}

let pt = Point()
pt.move(1, 2)
assert(pt.sum() == 3)

let counterObj = Counter(5)
counterObj.inc()
assert(counterObj.value == 6)
// line comment coverage
print("cangjie ")
println("advanced syntax ok")
