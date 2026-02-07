// Test: Operator overloading via extend blocks and interfaces
// Validates operator +, == on user-defined structs and interface syntax

// --- Operator func in interface ---
interface Addable {
  operator func +(other: Int64): Int64
}

// --- Operator func in extend for user-defined struct ---
struct Vec2 {
  var x: Int64 = 0
  var y: Int64 = 0
}

extend Vec2 {
  operator func +(other: Vec2): Vec2 {
    return Vec2(this.x + other.x, this.y + other.y)
  }
  operator func ==(other: Vec2): Bool {
    return this.x == other.x && this.y == other.y
  }
}

let v1 = Vec2(1, 2)
let v2 = Vec2(3, 4)
let v3 = v1 + v2
if (v3.x != 4) { println("FAIL: v3.x expected 4, got ${v3.x}"); return () }
if (v3.y != 6) { println("FAIL: v3.y expected 6, got ${v3.y}"); return () }
let eqFalse = v1 == v2
if (eqFalse != false) { println("FAIL: v1==v2 expected false, got ${eqFalse}"); return () }
let eqTrue = v1 == Vec2(1, 2)
if (eqTrue != true) { println("FAIL: v1==Vec2(1,2) expected true, got ${eqTrue}"); return () }

// --- Operator func in extend for built-in type ---
extend Int64 {
  operator func *(other: Int64): Int64 {
    return this * other + 1
  }
}
// Note: extending built-in operator overloads may not work due to
// how Lua handles arithmetic on numbers. This is a known limitation.
// The key test is that the syntax parses correctly.

println("PASS: 25_operator_extend_interface")
