// Test: Enum Type

// Simple enum with no-arg constructors
enum Direction {
  | North
  | South
  | East
  | West

  func name(): String {
    match (this) {
      case North =>
        return "North"
      case South =>
        return "South"
      case East =>
        return "East"
      case West =>
        return "West"
    }
    return "Unknown"
  }
}

let d = Direction.North
println(d.name())

// Enum with parameterized constructors
enum Color {
  | Red
  | Green
  | Blue(Int64)
  | RGB(Int64, Int64, Int64)

  func describe(): String {
    match (this) {
      case Red =>
        return "Red"
      case Green =>
        return "Green"
      case Blue(v) =>
        return "Blue(" .. tostring(v) .. ")"
      case RGB(r, g, b) =>
        return "RGB(" .. tostring(r) .. "," .. tostring(g) .. "," .. tostring(b) .. ")"
    }
    return "Unknown"
  }
}

let r = Color.Red
let g = Color.Green
let b = Color.Blue(128)
let rgb = Color.RGB(255, 128, 0)

println(r.describe())
println(g.describe())
println(b.describe())
println(rgb.describe())

// Recursive enum (expression tree)
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Mul(Expr, Expr)
}

func eval(e) {
  match (e) {
    case Num(n) =>
      return n
    case Add(a, b) =>
      return eval(a) + eval(b)
    case Mul(a, b) =>
      return eval(a) * eval(b)
  }
  return 0
}

// Build: (2 + 3) * 4
let e = Expr.Mul(Expr.Add(Expr.Num(2), Expr.Num(3)), Expr.Num(4))
println("(2+3)*4 = " .. tostring(eval(e)))

// Enum for Option type
enum Option {
  | Some(Int64)
  | None

  func isPresent(): Bool {
    match (this) {
      case Some(v) =>
        return true
      case None =>
        return false
    }
    return false
  }
}

let val = Option.Some(42)
let empty = Option.None
println("Some(42).isPresent() = " .. tostring(val.isPresent()))
println("None.isPresent() = " .. tostring(empty.isPresent()))

// Generic enum (type params are skipped, work via dynamic typing)
enum Result<T, E> {
  | Ok(T)
  | Err(E)

  func isOk(): Bool {
    match (this) {
      case Ok(v) =>
        return true
      case Err(e) =>
        return false
    }
    return false
  }
}

let ok = Result.Ok(42)
let err = Result.Err("something went wrong")
println("Ok(42).isOk() = " .. tostring(ok.isOk()))
println("Err(...).isOk() = " .. tostring(err.isOk()))

println("PASS: 12_enum")
