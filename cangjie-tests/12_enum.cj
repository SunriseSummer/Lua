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
if (d.name() != "North") { println("FAIL: d.name() expected North, got ${d.name()}"); return () }

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

if (r.describe() != "Red") { println("FAIL: Red.describe() expected Red, got ${r.describe()}"); return () }
if (g.describe() != "Green") { println("FAIL: Green.describe() expected Green, got ${g.describe()}"); return () }
if (b.describe() != "Blue(128)") { println("FAIL: Blue(128).describe() expected Blue(128), got ${b.describe()}"); return () }
if (rgb.describe() != "RGB(255,128,0)") { println("FAIL: RGB.describe() expected RGB(255,128,0), got ${rgb.describe()}"); return () }

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
if (evalResult != 20) { println("FAIL: (2+3)*4 expected 20, got ${evalResult}"); return () }

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
if (val.isPresent() != true) { println("FAIL: Some(42).isPresent() expected true, got ${val.isPresent()}"); return () }
if (empty.isPresent() != false) { println("FAIL: None.isPresent() expected false, got ${empty.isPresent()}"); return () }

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
if (ok.isOk() != true) { println("FAIL: Ok(42).isOk() expected true, got ${ok.isOk()}"); return () }
if (err.isOk() != false) { println("FAIL: Err(...).isOk() expected false, got ${err.isOk()}"); return () }

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
if (leafVal != 42) { println("FAIL: leaf value expected 42, got ${leafVal}"); return () }

// --- Unit type literal () used in match (Empty match) ---
let empty_tree = Empty
var matchedEmpty = false
match (empty_tree) {
    case Empty =>
        matchedEmpty = true
    case _ =>
        ()
}
if (matchedEmpty != true) { println("FAIL: empty tree match expected true, got ${matchedEmpty}"); return () }

println("PASS: 12_enum")
