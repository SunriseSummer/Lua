dofile("cangjie-tests/_testing.cj")

// Test: OOP with inheritance, enum, and pattern matching
// Demonstrates how the new Cangjie features work together

// -- Section: type hierarchy for expression evaluator --
interface Describable {
  func describe(): String
}

enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Sub(Expr, Expr)
  | Mul(Expr, Expr)
  | Neg(Expr)
}

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

// -- Section: expression evaluation --
let expr1 = Mul(
  Add(Num(2), Num(3)),
  Sub(Num(10), Num(4))
)
let r1 = eval(expr1)
expectEq(r1.value, 30, "(2+3)*(10-4) value")
expectEq(r1.expr_str, "((2+3)*(10-4))", "(2+3)*(10-4) expr_str")

let expr2 = Neg(Add(Num(5), Num(3)))
let r2 = eval(expr2)
expectEq(r2.value, -8, "-(5+3) value")

// -- Section: tuple for multi-value operations --
func analyze(expr_result) {
  return (expr_result.value, expr_result.steps, expr_result.value > 0)
}

let info = analyze(r1)
expectEq(info[0], 30, "analyze value")
expectTrue(info[2], "analyze positive")

// -- Section: polymorphism via inheritance --
expectEq(r1.toString(), "((2+3)*(10-4)) = 30 (steps=7)", "DetailedResult toString")
expectEq(Result(100, 1).toString(), "Result(100, steps=1)", "Result toString")

// -- Section: type pattern matching with class hierarchy --
func classifyResult(r): String {
  match (r) {
    case d: DetailedResult =>
      return "detailed: " + d.expr_str
    case r: Result =>
      return "basic: ${r.value}"
  }
  return "unknown"
}

expectEq(classifyResult(r1), "detailed: ((2+3)*(10-4))", "classifyResult detailed")
expectEq(classifyResult(Result(100, 1)), "basic: 100", "classifyResult basic")

if (!__test_failed) {
    println("PASS: usages/oop_enum_match")
}
