dofile("cangjie-tests/_testing.cj")

// Test: Lambda expressions — brace lambdas, typed/untyped params, closures, higher-order functions

// --- Brace lambda with typed parameters ---
let add = { x: Int64, y: Int64 => x + y }
expectEq(add(3, 4), 7, "add(3,4)")

// --- Brace lambda with single parameter ---
let double = { x: Int64 => x * 2 }
expectEq(double(5), 10, "double(5)")

// --- Brace lambda without type annotations ---
let mul = { a, b => a * b }
expectEq(mul(6, 7), 42, "mul(6,7)")

// --- Brace lambda with no parameters ---
let greeting = { => "Hello, World!" }
expectEq(greeting(), "Hello, World!", "greeting()")

// --- Parenthesized lambda syntax (also supported) ---
let square = () => 42
expectEq(square(), 42, "square()")

// --- Brace lambda passed as argument ---
func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 {
  return fn(a, b)
}
expectEq(apply(add, 10, 20), 30, "apply(add,10,20)")

// --- Brace lambda as inline argument ---
let inlineResult = apply({ x, y => x - y }, 100, 30)
expectEq(inlineResult, 70, "apply inline")

// --- Brace lambda with multi-statement body ---
let abs_val = { x: Int64 =>
  if (x < 0) {
    return -x
  }
  return x
}
expectEq(abs_val(-5), 5, "abs_val(-5)")
expectEq(abs_val(3), 3, "abs_val(3)")

// --- Brace lambda capturing outer variables (closure) ---
var base = 10
let addBase = { x => x + base }
expectEq(addBase(5), 15, "addBase(5)")

// --- Lambda returning lambda (higher-order) ---
let makeAdder = { n => { x => x + n } }
let add7 = makeAdder(7)
expectEq(add7(3), 10, "add7(3)")

if (!__test_failed) {
    println("PASS: 14_lambda")
}
