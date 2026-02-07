dofile("cangjie-tests/_testing.cj")

// Test: Functions

// -- Section: Basic function definition --
func add(a: Int64, b: Int64): Int64 {
  return a + b
}
let r_add = add(3, 4)
expectEq(r_add, 7, "add(3,4)")

// -- Section: Function with type annotations --
func multiply(x: Int64, y: Int64): Int64 {
  return x * y
}
let r_mul = multiply(5, 6)
expectEq(r_mul, 30, "multiply(5,6)")

// -- Section: Functions as first-class citizens --
let f = add
let r_f = f(10, 20)
expectEq(r_f, 30, "f(10,20)")

// -- Section: Function passed as argument --
func apply(fn, a, b) {
  return fn(a, b)
}
let r_apply = apply(add, 100, 200)
expectEq(r_apply, 300, "apply(add,100,200)")

// -- Section: Nested functions --
func outer() {
  let x = 10
  func inner() {
    return x + 5
  }
  return inner()
}
let r_outer = outer()
expectEq(r_outer, 15, "outer()")

// -- Section: Closures --
func makeAdder(n: Int64) {
  return func(x: Int64): Int64 {
    return x + n
  }
}
let add5 = makeAdder(5)
let add10 = makeAdder(10)
let r_add5 = add5(3)
expectEq(r_add5, 8, "add5(3)")
let r_add10 = add10(3)
expectEq(r_add10, 13, "add10(3)")

// -- Section: Counter closure --
func makeCounter() {
  var count: Int64 = 0
  return func(): Int64 {
    count = count + 1
    return count
  }
}
let counter = makeCounter()
let c1 = counter()
expectEq(c1, 1, "counter() first call")
let c2 = counter()
expectEq(c2, 2, "counter() second call")
let c3 = counter()
expectEq(c3, 3, "counter() third call")

// -- Section: Lambda expression --
let square = () => 42
let r_sq = square()
expectEq(r_sq, 42, "square()")

// -- Section: Anonymous function --
let double = func(x: Int64): Int64 { return x * 2 }
let r_dbl = double(7)
expectEq(r_dbl, 14, "double(7)")

// -- Section: Recursive function --
func factorial(n: Int64): Int64 {
  if (n <= 1) {
    return 1
  }
  return n * factorial(n - 1)
}
let r_fact = factorial(10)
expectEq(r_fact, 3628800, "factorial(10)")

if (!__test_failed) {
    println("PASS: 06_functions")
}
