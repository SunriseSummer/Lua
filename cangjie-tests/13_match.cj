// Test: Pattern Matching with match expression

// === Enum pattern matching ===
enum Color {
  | Red
  | Green
  | Blue(Int64)
}

func describeColor(c) {
  match (c) {
    case Red => {
      println("It is red")
    }
    case Green => {
      println("It is green")
    }
    case Blue(val) => {
      println("It is blue with value " .. tostring(val))
    }
  }
}

describeColor(Color.Red)
describeColor(Color.Green)
describeColor(Color.Blue(200))

// === Constant pattern matching ===
func describeNumber(n) {
  match (n) {
    case 0 => { println("zero") }
    case 1 => { println("one") }
    case 42 => { println("the answer") }
    case _ => { println("some number: " .. tostring(n)) }
  }
}

describeNumber(0)
describeNumber(1)
describeNumber(42)
describeNumber(99)

// === Wildcard pattern ===
enum Shape {
  | Circle(Float64)
  | Rectangle(Float64, Float64)
  | Triangle(Float64, Float64, Float64)
}

func getArea(s) {
  match (s) {
    case Circle(r) => {
      return 3.14159 * r * r
    }
    case Rectangle(w, h) => {
      return w * h
    }
    case _ => {
      return 0.0
    }
  }
  return 0.0
}

println("circle area: " .. tostring(getArea(Shape.Circle(5.0))))
println("rect area: " .. tostring(getArea(Shape.Rectangle(3.0, 4.0))))
println("triangle area: " .. tostring(getArea(Shape.Triangle(3.0, 4.0, 5.0))))

// === Recursive enum with pattern matching ===
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Sub(Expr, Expr)
  | Mul(Expr, Expr)
}

func eval(e) {
  match (e) {
    case Num(n) => {
      return n
    }
    case Add(a, b) => {
      return eval(a) + eval(b)
    }
    case Sub(a, b) => {
      return eval(a) - eval(b)
    }
    case Mul(a, b) => {
      return eval(a) * eval(b)
    }
  }
  return 0
}

// (1 + 2) * (4 - 1)
let expr1 = Expr.Mul(
  Expr.Add(Expr.Num(1), Expr.Num(2)),
  Expr.Sub(Expr.Num(4), Expr.Num(1))
)
println("(1+2)*(4-1) = " .. tostring(eval(expr1)))

// === Option type pattern matching ===
enum Option {
  | Some(Int64)
  | None
}

func getOrDefault(opt, default_val) {
  match (opt) {
    case Some(v) => {
      return v
    }
    case None => {
      return default_val
    }
  }
  return default_val
}

println("Some(42): " .. tostring(getOrDefault(Option.Some(42), 0)))
println("None: " .. tostring(getOrDefault(Option.None, -1)))

println("PASS: 13_match")
