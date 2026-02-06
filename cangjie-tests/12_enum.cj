// Test: Enum Type

// Simple enum with no-arg constructors
enum Direction {
  | North
  | South
  | East
  | West
}

let d = Direction.North
println(d.__tag)  // North

// Enum with parameterized constructors
enum Color {
  | Red
  | Green
  | Blue(Int64)
  | RGB(Int64, Int64, Int64)
}

let r = Color.Red
let b = Color.Blue(128)
let rgb = Color.RGB(255, 128, 0)

println(r.__tag)     // Red
println(b.__tag)     // Blue
println(b[1])        // 128
println(rgb.__tag)   // RGB
println(rgb[1])      // 255
println(rgb[2])      // 128
println(rgb[3])      // 0

// Enum constructors accessible without prefix
let red = Red
println(red.__tag)   // Red

let blue = Blue(64)
println(blue.__tag)  // Blue
println(blue[1])     // 64

// Recursive enum (expression tree)
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Mul(Expr, Expr)
}

// Build: (2 + 3) * 4
let e = Expr.Mul(Expr.Add(Expr.Num(2), Expr.Num(3)), Expr.Num(4))
println(e.__tag)      // Mul
println(e[1].__tag)   // Add
println(e[1][1].__tag)  // Num
println(e[1][1][1])   // 2

// Enum for Option type
enum Option {
  | Some(Int64)
  | None
}

let val = Option.Some(42)
let empty = Option.None
println(val.__tag)    // Some
println(val[1])       // 42
println(empty.__tag)  // None

println("PASS: 12_enum")
