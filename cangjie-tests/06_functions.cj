// Test: Functions
// Validates basic function definitions, first-class functions, closures,
// nested functions, lambdas, anonymous functions, and recursion.

// -- Section: Basic function definition --
func add(a: Int64, b: Int64): Int64 {
  return a + b
}
let r_add = add(3, 4)
if (r_add != 7) { println("FAIL: add(3,4) expected 7, got ${r_add}"); return () }

// -- Section: Function with type annotations --
func multiply(x: Int64, y: Int64): Int64 {
  return x * y
}
let r_mul = multiply(5, 6)
if (r_mul != 30) { println("FAIL: multiply(5,6) expected 30, got ${r_mul}"); return () }

// -- Section: Functions as first-class citizens --
let f = add
let r_f = f(10, 20)
if (r_f != 30) { println("FAIL: f(10,20) expected 30, got ${r_f}"); return () }

// -- Section: Function passed as argument --
func apply(fn, a, b) {
  return fn(a, b)
}
let r_apply = apply(add, 100, 200)
if (r_apply != 300) { println("FAIL: apply(add,100,200) expected 300, got ${r_apply}"); return () }

// -- Section: Nested functions --
func outer() {
  let x = 10
  func inner() {
    return x + 5
  }
  return inner()
}
let r_outer = outer()
if (r_outer != 15) { println("FAIL: outer() expected 15, got ${r_outer}"); return () }

// -- Section: Closures --
func makeAdder(n: Int64) {
  return func(x: Int64): Int64 {
    return x + n
  }
}
let add5 = makeAdder(5)
let add10 = makeAdder(10)
let r_add5 = add5(3)
if (r_add5 != 8) { println("FAIL: add5(3) expected 8, got ${r_add5}"); return () }
let r_add10 = add10(3)
if (r_add10 != 13) { println("FAIL: add10(3) expected 13, got ${r_add10}"); return () }

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
if (c1 != 1) { println("FAIL: counter() first call expected 1, got ${c1}"); return () }
let c2 = counter()
if (c2 != 2) { println("FAIL: counter() second call expected 2, got ${c2}"); return () }
let c3 = counter()
if (c3 != 3) { println("FAIL: counter() third call expected 3, got ${c3}"); return () }

// -- Section: Lambda expression --
let square = () => 42
let r_sq = square()
if (r_sq != 42) { println("FAIL: square() expected 42, got ${r_sq}"); return () }

// -- Section: Anonymous function --
let double = func(x: Int64): Int64 { return x * 2 }
let r_dbl = double(7)
if (r_dbl != 14) { println("FAIL: double(7) expected 14, got ${r_dbl}"); return () }

// -- Section: Recursive function --
func factorial(n: Int64): Int64 {
  if (n <= 1) {
    return 1
  }
  return n * factorial(n - 1)
}
let r_fact = factorial(10)
if (r_fact != 3628800) { println("FAIL: factorial(10) expected 3628800, got ${r_fact}"); return () }

println("PASS: 06_functions")
