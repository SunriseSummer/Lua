// Test: Functions

// Basic function definition
func add(a: Int64, b: Int64): Int64 {
  return a + b
}
println("add(3, 4) = ${add(3, 4)}")

// Function with type annotations
func multiply(x: Int64, y: Int64): Int64 {
  return x * y
}
println("multiply(5, 6) = ${multiply(5, 6)}")

// Functions as first-class citizens
let f = add
println("f(10, 20) = ${f(10, 20)}")

// Function passed as argument
func apply(fn, a, b) {
  return fn(a, b)
}
println("apply(add, 100, 200) = ${apply(add, 100, 200)}")

// Nested functions
func outer() {
  let x = 10
  func inner() {
    return x + 5
  }
  return inner()
}
println("outer() = ${outer()}")

// Closures
func makeAdder(n: Int64) {
  return func(x: Int64): Int64 {
    return x + n
  }
}
let add5 = makeAdder(5)
let add10 = makeAdder(10)
println("add5(3) = ${add5(3)}")
println("add10(3) = ${add10(3)}")

// Counter closure
func makeCounter() {
  var count: Int64 = 0
  return func(): Int64 {
    count = count + 1
    return count
  }
}
let counter = makeCounter()
println("counter() = ${counter()}")
println("counter() = ${counter()}")
println("counter() = ${counter()}")

// Lambda expression
let square = () => 42
println("lambda = ${square()}")

// Anonymous function
let double = func(x: Int64): Int64 { return x * 2 }
println("double(7) = ${double(7)}")

// Recursive function
func factorial(n: Int64): Int64 {
  if (n <= 1) {
    return 1
  }
  return n * factorial(n - 1)
}
println("factorial(10) = ${factorial(10)}")

println("PASS: 06_functions")
