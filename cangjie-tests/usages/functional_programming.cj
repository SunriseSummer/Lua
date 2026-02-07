dofile("cangjie-tests/_testing.cj")

// Test: Functional programming with lambda and higher-order functions

// -- Section: higher-order function library --
func map(arr, fn) {
  let result = {}
  var i = 1
  while (arr[i] != nil) {
    result[i] = fn(arr[i])
    i = i + 1
  }
  return result
}

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

func reduce(arr, init, fn) {
  var acc = init
  var i = 1
  while (arr[i] != nil) {
    acc = fn(acc, arr[i])
    i = i + 1
  }
  return acc
}

func compose(f, g) {
  return { x => f(g(x)) }
}

func pipe(value, fns) {
  var result = value
  var i = 1
  while (fns[i] != nil) {
    result = fns[i](result)
    i = i + 1
  }
  return result
}

// -- Section: map with brace lambda --
let numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
let doubled = map(numbers, { x => x * 2 })
expectEq(doubled[1], 2, "map doubled[1]")
expectEq(doubled[5], 10, "map doubled[5]")
expectEq(doubled[10], 20, "map doubled[10]")

// -- Section: filter with brace lambda --
let evens = filter(numbers, { x => x % 2 == 0 })
expectEq(evens[1], 2, "filter evens[1]")
expectEq(evens[2], 4, "filter evens[2]")
expectEq(evens[5], 10, "filter evens[5]")

// -- Section: reduce with brace lambda --
let sum = reduce(numbers, 0, { acc, x => acc + x })
expectEq(sum, 55, "reduce sum")

let product = reduce(numbers, 1, { acc, x => acc * x })
expectEq(product, 3628800, "reduce product")

// -- Section: compose --
let addOne = { x => x + 1 }
let timesTwo = { x => x * 2 }
let addOneThenDouble = compose(timesTwo, addOne)
expectEq(addOneThenDouble(5), 12, "compose (5+1)*2")

// -- Section: pipe --
let result = pipe(5, {addOne, timesTwo, addOne})
expectEq(result, 13, "pipe (5+1)*2+1")

// -- Section: curried function --
let multiply = { a => { b => a * b } }
let triple = multiply(3)
expectEq(triple(7), 21, "curried triple(7)")

// -- Section: lambda with closure for state --
func makeCounter() {
  var count = 0
  return {
    increment = { => count = count + 1 },
    decrement = { => count = count - 1 },
    getCount = { => count }
  }
}

let counter = makeCounter()
counter.increment()
counter.increment()
counter.increment()
counter.decrement()
expectEq(counter.getCount(), 2, "counter after inc*3 dec*1")

// -- Section: immediate invocation of lambda --
let result2 = ({ x, y => x ** 2 + y ** 2 })(3, 4)
expectEq(result2, 25.0, "IIFE 3^2 + 4^2")

if (!__test_failed) {
    println("PASS: usages/functional_programming")
}
