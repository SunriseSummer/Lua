dofile("cangjie-tests/_testing.cj")

// Test: Expression Evaluation (if, match, block expressions and implicit return)

// -- Section: if expression --
let x = if (3 > 2) { 10 } else { 20 }
expectEq(x, 10, "if expr (true branch)")

let y = if (1 > 2) { 10 } else { 20 }
expectEq(y, 20, "if expr (false branch)")

// -- Section: if expression with else if --
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
expectEq(level, "B", "if-else-if grade level")

// -- Section: if expression without else (nil) --
let z = if (false) { 42 }
expectNil(z, "if no else")

// -- Section: if expression with computation --
let result = if (10 % 2 == 0) {
  var s = "even"
  s
} else {
  "odd"
}
expectEq(result, "even", "if expr with computation")

// -- Section: match expression with constants --
let day = 3
let dayName = match (day) {
  case 1 => "Monday"
  case 2 => "Tuesday"
  case 3 => "Wednesday"
  case 4 => "Thursday"
  case 5 => "Friday"
  case _ => "Weekend"
}
expectEq(dayName, "Wednesday", "match day name")

// -- Section: match expression with enum --
enum Shape {
  | Circle(Int64)
  | Rect(Int64, Int64)
}

let s = Circle(5)
let area = match (s) {
  case Circle(r) => r * r * 3
  case Rect(w, h) => w * h
}
expectEq(area, 75, "match circle area")

// -- Section: match expression with no match (nil) --
let nomatch = match (99) {
  case 1 => "one"
  case 2 => "two"
}
expectNil(nomatch, "match no match")

// -- Section: block expression --
let sum = {
  var s = 0
  for (i in 0..10) {
    s = s + i
  }
  s
}
expectEq(sum, 45, "block expr sum 0..9")

let doubled = {
  let x = 21
  x * 2
}
expectEq(doubled, 42, "block expr 21*2")

// -- Section: keyword-only block expression --
let empty_val = { let _x = 0 }
expectNil(empty_val, "keyword-only block")

// -- Section: nested block expression --
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
expectEq(nested, 10, "nested blocks")

// -- Section: function implicit return --
func add(a: Int64, b: Int64): Int64 {
  a + b
}
expectEq(add(3, 4), 7, "implicit return add")

func computeSum(n: Int64): Int64 {
  var s = 0
  for (i in 0..n) {
    s = s + i
  }
  s
}
expectEq(computeSum(100), 4950, "implicit return computeSum")

func explicitReturn(x: Int64): Int64 {
  if (x < 0) {
    return -x
  }
  return x
}
expectEq(explicitReturn(-5), 5, "explicit return abs")

func greet(name: String): String {
  "Hello, " + name + "!"
}
expectEq(greet("World"), "Hello, World!", "implicit return greet")

// -- Section: undetermined expressions evaluate to nil --
let w = while (false) { println("unreachable") }
expectNil(w, "while expr is nil")

let f = for (i in 0..0) { println("unreachable") }
expectNil(f, "for expr is nil")

if (!__test_failed) {
    println("PASS: ext-features/05_expression_eval")
}
