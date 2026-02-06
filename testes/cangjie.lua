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

func range(start: Int, stop: Int) {
  return func (_, current) {
    var next = current + 1
    if (next <= stop) {
      return next
    } else {
      return null
    }
  }, null, start - 1
}

var sum = 0
for (i in range(1, 3)) {
  sum = sum + i
}

while (sum < 10 && counter != 2) {
  counter = counter + 1
  if (counter == 1 || sum == 6) {
    sum = sum + 1
  } else if (counter == 2) {
    sum = sum + 2
  }
}

assert(add(sum, counter) == 11)
assert(doubler(sum) == 18)
// line comment coverage
print("cangjie basic syntax ok")
