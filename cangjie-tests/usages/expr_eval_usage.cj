// Usage: Expression Evaluation and Enum Operators
// Demonstrates practical use of expression evaluation features

// === Calculator with enum types ===

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

// Build expression: (2 + 3) * 4
let expr = Num(2) + Num(3)
let expr2 = expr * Num(4)
let result = evaluate(expr2)
println("(2 + 3) * 4 = " + tostring(result))

// === Using if/match/block expressions for concise code ===

func classify(score: Int64): String {
  return if (score >= 90) { "Excellent" }
  else if (score >= 70) { "Good" }
  else if (score >= 60) { "Pass" }
  else { "Fail" }
}

// Process scores using block expression  
let scores = [85, 92, 67, 45, 78]
for (i in 0..scores.size) {
  let s = scores[i]
  let label = classify(s)
  println("Score " + tostring(s) + ": " + label)
}

// === Block expression for complex initialization ===
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
println("Fibonacci(10) = " + tostring(fibonacci_10))

// === Match expression for value mapping ===
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

let s1 = Ok
let s2 = Error("not found")
let s3 = Loading
println(statusMessage(s1))
println(statusMessage(s2))
println(statusMessage(s3))

// === Function implicit return for clean code ===

func max(a: Int64, b: Int64): Int64 {
  return if (a > b) { a } else { b }
}

func min(a: Int64, b: Int64): Int64 {
  return if (a < b) { a } else { b }
}

func clamp(value: Int64, lo: Int64, hi: Int64): Int64 {
  return max(lo, min(value, hi))
}

println("clamp(15, 0, 10) = " + tostring(clamp(15, 0, 10)))
println("clamp(-5, 0, 10) = " + tostring(clamp(-5, 0, 10)))
println("clamp(5, 0, 10) = " + tostring(clamp(5, 0, 10)))

println("PASS: expr_eval_usage")
