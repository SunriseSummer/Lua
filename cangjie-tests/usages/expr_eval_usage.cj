dofile("cangjie-tests/_testing.cj")

// Test: Expression evaluation and enum operators usage
// Demonstrates practical use of expression evaluation features

// -- Section: calculator with enum types --
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Mul(Expr, Expr)

  operator func +(other: Expr): Expr {
    return Add(self, other)
  }

  operator func *(other: Expr): Expr {
    return Mul(self, other)
  }
}

func evaluate(e: Expr): Int64 {
  return match (e) {
    case Num(n) => n
    case Add(left, right) => evaluate(left) + evaluate(right)
    case Mul(left, right) => evaluate(left) * evaluate(right)
  }
}

let expr = Num(2) + Num(3)
let expr2 = expr * Num(4)
let result = evaluate(expr2)
expectEq(result, 20, "(2 + 3) * 4")

// -- Section: if expression for classification --
func classify(score: Int64): String {
  return if (score >= 90) { "Excellent" }
  else if (score >= 70) { "Good" }
  else if (score >= 60) { "Pass" }
  else { "Fail" }
}

expectEq(classify(85), "Good", "classify 85")
expectEq(classify(92), "Excellent", "classify 92")
expectEq(classify(67), "Pass", "classify 67")
expectEq(classify(45), "Fail", "classify 45")
expectEq(classify(78), "Good", "classify 78")

// -- Section: block expression for initialization --
let fibonacci_10 = {
  var a = 0
  var b = 1
  for (i in 0..9) {
    let temp = a + b
    a = b
    b = temp
  }
  b
}
expectEq(fibonacci_10, 55, "fibonacci(10)")

// -- Section: match expression for value mapping --
enum Status {
  | Ok
  | Error(String)
  | Loading
}

func statusMessage(s: Status): String {
  return match (s) {
    case Ok => "Operation completed successfully"
    case Error(msg) => "Error: " + msg
    case Loading => "Please wait..."
  }
}

expectEq(statusMessage(Ok), "Operation completed successfully", "status Ok")
expectEq(statusMessage(Error("not found")), "Error: not found", "status Error")
expectEq(statusMessage(Loading), "Please wait...", "status Loading")

// -- Section: function implicit return for clean code --
func max(a: Int64, b: Int64): Int64 {
  return if (a > b) { a } else { b }
}

func min(a: Int64, b: Int64): Int64 {
  return if (a < b) { a } else { b }
}

func clamp(value: Int64, lo: Int64, hi: Int64): Int64 {
  return max(lo, min(value, hi))
}

expectEq(clamp(15, 0, 10), 10, "clamp(15, 0, 10)")
expectEq(clamp(-5, 0, 10), 0, "clamp(-5, 0, 10)")
expectEq(clamp(5, 0, 10), 5, "clamp(5, 0, 10)")

if (!__test_failed) {
    println("PASS: usages/expr_eval_usage")
}
