// Comprehensive Usage: OOP with Inheritance, Enum, and Pattern Matching
// Demonstrates how the new Cangjie features work together

// === Define a type hierarchy for a simple expression evaluator ===

// Base interface
interface Describable {
  func describe(): String
}

// Enum for expression types with member functions
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Sub(Expr, Expr)
  | Mul(Expr, Expr)
  | Neg(Expr)
}

// Class hierarchy for evaluation results
class Result {
  var value: Int64
  var steps: Int64
  init(value: Int64, steps: Int64) {
    this.value = value
    this.steps = steps
  }
  func toString(): String {
    return "Result(${this.value}, steps=${this.steps})"
  }
}

class DetailedResult <: Result {
  var expr_str: String
  init(value: Int64, steps: Int64, expr_str: String) {
    this.value = value
    this.steps = steps
    this.expr_str = expr_str
  }
  func toString(): String {
    return "${this.expr_str} = ${this.value} (steps=${this.steps})"
  }
}

// Evaluator using pattern matching on recursive enums
func eval(e) {
  match (e) {
    case Num(n) =>
      return DetailedResult(n, 1, tostring(n))
    case Add(a, b) =>
      let ra = eval(a)
      let rb = eval(b)
      return DetailedResult(
        ra.value + rb.value,
        ra.steps + rb.steps + 1,
        "(" + ra.expr_str + "+" + rb.expr_str + ")"
      )
    case Sub(a, b) =>
      let ra = eval(a)
      let rb = eval(b)
      return DetailedResult(
        ra.value - rb.value,
        ra.steps + rb.steps + 1,
        "(" + ra.expr_str + "-" + rb.expr_str + ")"
      )
    case Mul(a, b) =>
      let ra = eval(a)
      let rb = eval(b)
      return DetailedResult(
        ra.value * rb.value,
        ra.steps + rb.steps + 1,
        "(" + ra.expr_str + "*" + rb.expr_str + ")"
      )
    case Neg(a) =>
      let ra = eval(a)
      return DetailedResult(
        0 - ra.value,
        ra.steps + 1,
        "(-" + ra.expr_str + ")"
      )
  }
  return Result(0, 0)
}

// Build expression: (2 + 3) * (10 - 4)
let expr1 = Mul(
  Add(Num(2), Num(3)),
  Sub(Num(10), Num(4))
)

let r1 = eval(expr1)
println(r1.toString())

// Build: -(5 + 3)
let expr2 = Neg(Add(Num(5), Num(3)))
let r2 = eval(expr2)
println(r2.toString())

// === Use tuples for multi-value operations ===
func analyze(expr_result) {
  return (expr_result.value, expr_result.steps, expr_result.value > 0)
}

let info = analyze(r1)
println("value=${info[0]} steps=${info[1]} positive=${info[2]}")

// === Polymorphism via inheritance ===
func printResult(r) {
  // This works due to dynamic dispatch - calls the right toString
  println("  -> " + r.toString())
}

printResult(r1)
printResult(r2)

// === Type pattern matching with class hierarchy ===
func classifyResult(r) {
  match (r) {
    case d: DetailedResult =>
      println("detailed: " + d.expr_str)
    case r: Result =>
      println("basic result: ${r.value}")
  }
}

classifyResult(r1)
classifyResult(Result(100, 1))

println("PASS: usages/oop_enum_match")
