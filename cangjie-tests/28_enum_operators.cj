dofile("cangjie-tests/_testing.cj")

// Test: Enum Operator Overloading
// Validates +, -, == operators on enums, toString, and combined operators with methods

// --- Enum with operator overloading ---
enum Money {
  | Yuan(Int64)

  operator func +(other: Money): Money {
    match (self) {
      case Yuan(a) => match (other) {
        case Yuan(b) => return Yuan(a + b)
      }
    }
  }

  operator func -(other: Money): Money {
    match (self) {
      case Yuan(a) => match (other) {
        case Yuan(b) => return Yuan(a - b)
      }
    }
  }

  operator func ==(other: Money): Bool {
    match (self) {
      case Yuan(a) => match (other) {
        case Yuan(b) => return a == b
      }
    }
  }

  func value(): Int64 {
    match (this) {
      case Yuan(v) => return v
    }
  }
}

// --- Test + operator ---
let m1 = Yuan(100)
let m2 = Yuan(200)
let m3 = m1 + m2
expectEq(m3.value(), 300, "m3.value()")

// --- Test - operator ---
let m4 = m3 - m1
expectEq(m4.value(), 200, "m4.value()")

// --- Test == operator ---
let m5 = Yuan(200)
let eqTrue = m2 == m5
expectTrue(eqTrue, "m2==m5")
let eqFalse = m1 == m2
expectFalse(eqFalse, "m1==m2")

// --- Enum with toString operator ---
enum Color {
  | Red
  | Green
  | Blue

  operator func toString(): String {
    match (this) {
      case Red => return "Red"
      case Green => return "Green"
      case Blue => return "Blue"
    }
  }
}

let c = Red
let colorStr = tostring(c)
expectEq(colorStr, "Red", "Color toString")

// --- Enum with multiple operators and methods combined ---
enum Vec2 {
  | V(Int64, Int64)

  operator func +(other: Vec2): Vec2 {
    match (self) {
      case V(x1, y1) => match (other) {
        case V(x2, y2) => return V(x1 + x2, y1 + y2)
      }
    }
  }

  func x(): Int64 {
    match (this) {
      case V(xv, _) => return xv
    }
  }

  func y(): Int64 {
    match (this) {
      case V(_, yv) => return yv
    }
  }
}

let v1 = V(1, 2)
let v2 = V(3, 4)
let v3 = v1 + v2
expectEq(v3.x(), 4, "Vec2 v3.x()")
expectEq(v3.y(), 6, "Vec2 v3.y()")

if (!__test_failed) {
    println("PASS: 28_enum_operators")
}
