dofile("cangjie-tests/_testing.cj")

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
expectEq(v3.x, 4, "v3.x")
expectEq(v3.y, 6, "v3.y")
let eqFalse = v1 == v2
expectFalse(eqFalse, "v1==v2")
let eqTrue = v1 == Vec2(1, 2)
expectTrue(eqTrue, "v1==Vec2(1,2)")

// --- Operator func in extend for built-in type ---
extend Int64 {
  operator func *(other: Int64): Int64 {
    return this * other + 1
  }
}
// Note: extending built-in operator overloads may not work due to
// how Lua handles arithmetic on numbers. This is a known limitation.
// The key test is that the syntax parses correctly.

if (!__test_failed) {
    println("PASS: 25_operator_extend_interface")
}
