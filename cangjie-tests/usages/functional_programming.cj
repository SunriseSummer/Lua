// Comprehensive Usage: Functional Programming with Lambda and Higher-Order Functions

// === Higher-order function library ===

// Map function: applies fn to each element
func map(arr, fn) {
  let result = {}
  var i = 1
  while (arr[i] != nil) {
    result[i] = fn(arr[i])
    i = i + 1
  }
  return result
}

// Filter function: keeps elements matching predicate
func filter(arr, pred) {
  let result = {}
  var i = 1
  var j = 1
  while (arr[i] != nil) {
    if (pred(arr[i])) {
      result[j] = arr[i]
      j = j + 1
    }
    i = i + 1
  }
  return result
}

// Reduce function: folds array with accumulator
func reduce(arr, init, fn) {
  var acc = init
  var i = 1
  while (arr[i] != nil) {
    acc = fn(acc, arr[i])
    i = i + 1
  }
  return acc
}

// Compose two functions
func compose(f, g) {
  return { x => f(g(x)) }
}

// Pipe: apply a series of functions
func pipe(value, fns) {
  var result = value
  var i = 1
  while (fns[i] != nil) {
    result = fns[i](result)
    i = i + 1
  }
  return result
}

// === Usage examples ===

let numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

// Map with brace lambda
let doubled = map(numbers, { x => x * 2 })
print("doubled: ")
var i = 1
while (doubled[i] != nil) {
  print("${doubled[i]} ")
  i = i + 1
}
println()

// Filter with brace lambda
let evens = filter(numbers, { x => x % 2 == 0 })
print("evens: ")
i = 1
while (evens[i] != nil) {
  print("${evens[i]} ")
  i = i + 1
}
println()

// Reduce with brace lambda
let sum = reduce(numbers, 0, { acc, x => acc + x })
println("sum = ${sum}")

let product = reduce(numbers, 1, { acc, x => acc * x })
println("product = ${product}")

// Compose functions
let addOne = { x => x + 1 }
let timesTwo = { x => x * 2 }
let addOneThenDouble = compose(timesTwo, addOne)
println("addOneThenDouble(5) = ${addOneThenDouble(5)}")  // (5+1)*2 = 12

// Pipe
let result = pipe(5, {addOne, timesTwo, addOne})
println("pipe(5, [+1, *2, +1]) = ${result}")  // ((5+1)*2)+1 = 13

// Curried function using nested lambdas
let multiply = { a => { b => a * b } }
let triple = multiply(3)
println("triple(7) = ${triple(7)}")

// Lambda with closure for state
func makeCounter() {
  var count = 0
  return {
    increment = { => count = count + 1 },
    decrement = { => count = count - 1 },
    getCount = { => count }
  }
}

// Use Lua table with lambda fields as module pattern
let counter = makeCounter()
counter.increment()
counter.increment()
counter.increment()
counter.decrement()
println("counter = ${counter.getCount()}")  // 2

// Immediate invocation of lambda
let result2 = ({ x, y => x ** 2 + y ** 2 })(3, 4)
println("3^2 + 4^2 = ${result2}")  // 25

println("PASS: 10_functional_programming")
