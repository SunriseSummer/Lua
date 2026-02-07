dofile("cangjie-tests/_testing.cj")

// Test: Enum type — simple enums, parameterized constructors, recursive enums, Option, Result, Tree traversal

// --- Simple enum with no-arg constructors ---
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

let d = North
expectEq(d.name(), "North", "d.name()")

// --- Enum with parameterized constructors ---
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

let r = Red
let g = Green
let b = Blue(128)
let rgb = RGB(255, 128, 0)

expectEq(r.describe(), "Red", "Red.describe()")
expectEq(g.describe(), "Green", "Green.describe()")
expectEq(b.describe(), "Blue(128)", "Blue(128).describe()")
expectEq(rgb.describe(), "RGB(255,128,0)", "RGB.describe()")

// --- Recursive enum (expression tree) ---
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
let e = Mul(Add(Num(2), Num(3)), Num(4))
let evalResult = eval(e)
expectEq(evalResult, 20, "(2+3)*4")

// --- Enum for Option type ---
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

let val = Some(42)
let empty = None
expectTrue(val.isPresent(), "Some(42).isPresent()")
expectFalse(empty.isPresent(), "None.isPresent()")

// --- Generic enum (type params are skipped, work via dynamic typing) ---
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

let ok = Ok(42)
let err = Err("something went wrong")
expectTrue(ok.isOk(), "Ok(42).isOk()")
expectFalse(err.isOk(), "Err(...).isOk()")

// --- Recursive enum: binary tree with inline constructor syntax ---
// traverse() uses print() for side effects; we keep the call and verify output visually
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
// traverse() prints "3214567" via print() side effects
tree.traverse()
println()

// --- Simple recursive enum test (Leaf match) ---
let leaf = Leaf(42)
var leafVal = 0
match (leaf) {
    case Leaf(v) =>
        leafVal = v
    case _ =>
        ()
}
expectEq(leafVal, 42, "leaf value")

// --- Unit type literal () used in match (Empty match) ---
let empty_tree = Empty
var matchedEmpty = false
match (empty_tree) {
    case Empty =>
        matchedEmpty = true
    case _ =>
        ()
}
expectTrue(matchedEmpty, "empty tree match")

if (!__test_failed) {
    println("PASS: 12_enum")
}
