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
        return "Blue(${v})"
      case RGB(r, g, b) =>
        return "RGB(${r},${g},${b})"
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
println("(2+3)*4 = ${eval(e)}")

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
println("Some(42).isPresent() = ${val.isPresent()}")
println("None.isPresent() = ${empty.isPresent()}")

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
println("Ok(42).isOk() = ${ok.isOk()}")
println("Err(...).isOk() = ${err.isOk()}")

// Recursive enum: binary tree with inline constructor syntax
enum Tree {
    Empty | Leaf(Int64) | Node(Int64, Tree, Tree)

    func traverse(): Unit {
        match (this) {
            case Empty => ()
            case Leaf(value) => print(value)
            case Node(value, left, right) =>
                left.traverse()
                print(value)
                right.traverse()
        }
    }
}

let tree = Node(1,
    Node(2, Node(3, Empty, Leaf(4)), Empty),
    Node(5, Leaf(6), Leaf(7)))
tree.traverse()
println()

// Simple recursive enum test
let leaf = Leaf(42)
match (leaf) {
    case Leaf(v) =>
        println("leaf value = ${v}")
    case _ =>
        println("not a leaf")
}

// Unit type literal () used in match
let empty = Empty
match (empty) {
    case Empty =>
        ()  // no-op, Unit literal
        println("empty tree")
    case _ =>
        println("not empty")
}

println("PASS: 12_enum")
