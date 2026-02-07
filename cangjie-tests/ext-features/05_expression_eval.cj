// Test: Expression Evaluation (if, match, block expressions and implicit return)

// === If Expression ===

// Basic if expression
let x = if (3 > 2) { 10 } else { 20 }
println("if expr (true): " + tostring(x))

let y = if (1 > 2) { 10 } else { 20 }
println("if expr (false): " + tostring(y))

// If expression with else if
let grade = 85
let level = if (grade >= 90) {
  "A"
} else if (grade >= 80) {
  "B"
} else if (grade >= 70) {
  "C"
} else {
  "D"
}
println("grade level: " + level)

// If expression without else (value is nil)
let z = if (false) { 42 }
println("if no else: " + tostring(z))

// If expression with computation in branches
let result = if (10 % 2 == 0) {
  var s = "even"
  s
} else {
  "odd"
}
println("10 is: " + result)


// === Match Expression ===

// Basic match expression with constants
let day = 3
let dayName = match (day) {
  case 1 => "Monday"
  case 2 => "Tuesday"
  case 3 => "Wednesday"
  case 4 => "Thursday"
  case 5 => "Friday"
  case _ => "Weekend"
}
println("day 3: " + dayName)

// Match expression with enum
enum Shape {
  | Circle(Int64)
  | Rect(Int64, Int64)
}

let s = Circle(5)
let area = match (s) {
  case Circle(r) => r * r * 3
  case Rect(w, h) => w * h
}
println("circle area: " + tostring(area))

// Match expression with no match (nil)
let nomatch = match (99) {
  case 1 => "one"
  case 2 => "two"
}
println("no match: " + tostring(nomatch))


// === Block Expression ===

// Basic block expression
let sum = {
  var s = 0
  for (i in 0..10) {
    s = s + i
  }
  s
}
println("sum 0..9: " + tostring(sum))

// Block expression with variable
let doubled = {
  let x = 21
  x * 2
}
println("21 * 2 = " + tostring(doubled))

// Empty block expression (nil) - using explicit empty block syntax
let empty_val = { let _x = 0 }
println("keyword-only block: " + tostring(empty_val))

// Nested block expression
let nested = {
  let a = {
    var v = 1
    v + 2
  }
  let b = {
    var v = 3
    v + 4
  }
  a + b
}
println("nested blocks: " + tostring(nested))


// === Function Implicit Return ===

// Function with last expression as return value
func add(a: Int64, b: Int64): Int64 {
  a + b
}
println("add(3,4) = " + tostring(add(3, 4)))

// Function with variable and implicit return
func computeSum(n: Int64): Int64 {
  var s = 0
  for (i in 0..n) {
    s = s + i
  }
  s
}
println("sum(100) = " + tostring(computeSum(100)))

// Function with explicit return still works
func explicitReturn(x: Int64): Int64 {
  if (x < 0) {
    return -x
  }
  return x
}
println("abs(-5) = " + tostring(explicitReturn(-5)))

// Function with string implicit return
func greet(name: String): String {
  "Hello, " + name + "!"
}
println(greet("World"))

// === Undetermined expressions evaluate to nil ===
// while expression value is nil
let w = while (false) { println("unreachable") }
println("while expr: " + tostring(w))

// for expression value is nil
let f = for (i in 0..0) { println("unreachable") }
println("for expr: " + tostring(f))

println("PASS: 05_expression_eval")
