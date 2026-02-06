// Test: Lambda expressions (Cangjie brace lambda syntax)

// Brace lambda with typed parameters
let add = { x: Int64, y: Int64 => x + y }
println("add(3, 4) = ${add(3, 4)}")

// Brace lambda with single parameter
let double = { x: Int64 => x * 2 }
println("double(5) = ${double(5)}")

// Brace lambda without type annotations
let mul = { a, b => a * b }
println("mul(6, 7) = ${mul(6, 7)}")

// Brace lambda with no parameters
let greeting = { => "Hello, World!" }
println("greeting() = ${greeting()}")

// Parenthesized lambda syntax (also supported)
let square = () => 42
println("square() = ${square()}")

// Brace lambda passed as argument
func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 {
  return fn(a, b)
}
println("apply(add, 10, 20) = ${apply(add, 10, 20)}")

// Brace lambda as inline argument
println("apply inline = ${apply({ x, y => x - y }, 100, 30)}")

// Brace lambda with multi-statement body
let abs_val = { x: Int64 =>
  if (x < 0) {
    return -x
  }
  return x
}
println("abs(-5) = ${abs_val(-5)}")
println("abs(3) = ${abs_val(3)}")

// Brace lambda capturing outer variables (closure)
var base = 10
let addBase = { x => x + base }
println("addBase(5) = ${addBase(5)}")

// Lambda returning lambda (higher-order)
let makeAdder = { n => { x => x + n } }
let add7 = makeAdder(7)
println("add7(3) = ${add7(3)}")

println("PASS: 14_lambda")
