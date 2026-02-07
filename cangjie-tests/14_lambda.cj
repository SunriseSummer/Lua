// Test: Lambda expressions — brace lambdas, typed/untyped params, closures, higher-order functions

// --- Brace lambda with typed parameters ---
let add = { x: Int64, y: Int64 => x + y }
if (add(3, 4) != 7) { println("FAIL: add(3,4) expected 7, got ${add(3, 4)}"); return () }

// --- Brace lambda with single parameter ---
let double = { x: Int64 => x * 2 }
if (double(5) != 10) { println("FAIL: double(5) expected 10, got ${double(5)}"); return () }

// --- Brace lambda without type annotations ---
let mul = { a, b => a * b }
if (mul(6, 7) != 42) { println("FAIL: mul(6,7) expected 42, got ${mul(6, 7)}"); return () }

// --- Brace lambda with no parameters ---
let greeting = { => "Hello, World!" }
if (greeting() != "Hello, World!") { println("FAIL: greeting() expected Hello, World!, got ${greeting()}"); return () }

// --- Parenthesized lambda syntax (also supported) ---
let square = () => 42
if (square() != 42) { println("FAIL: square() expected 42, got ${square()}"); return () }

// --- Brace lambda passed as argument ---
func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 {
  return fn(a, b)
}
if (apply(add, 10, 20) != 30) { println("FAIL: apply(add,10,20) expected 30, got ${apply(add, 10, 20)}"); return () }

// --- Brace lambda as inline argument ---
let inlineResult = apply({ x, y => x - y }, 100, 30)
if (inlineResult != 70) { println("FAIL: apply inline expected 70, got ${inlineResult}"); return () }

// --- Brace lambda with multi-statement body ---
let abs_val = { x: Int64 =>
  if (x < 0) {
    return -x
  }
  return x
}
if (abs_val(-5) != 5) { println("FAIL: abs_val(-5) expected 5, got ${abs_val(-5)}"); return () }
if (abs_val(3) != 3) { println("FAIL: abs_val(3) expected 3, got ${abs_val(3)}"); return () }

// --- Brace lambda capturing outer variables (closure) ---
var base = 10
let addBase = { x => x + base }
if (addBase(5) != 15) { println("FAIL: addBase(5) expected 15, got ${addBase(5)}"); return () }

// --- Lambda returning lambda (higher-order) ---
let makeAdder = { n => { x => x + n } }
let add7 = makeAdder(7)
if (add7(3) != 10) { println("FAIL: add7(3) expected 10, got ${add7(3)}"); return () }

println("PASS: 14_lambda")
