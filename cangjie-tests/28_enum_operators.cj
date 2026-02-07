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
if (m3.value() != 300) { println("FAIL: m3.value() expected 300, got ${m3.value()}"); return () }

// --- Test - operator ---
let m4 = m3 - m1
if (m4.value() != 200) { println("FAIL: m4.value() expected 200, got ${m4.value()}"); return () }

// --- Test == operator ---
let m5 = Yuan(200)
let eqTrue = m2 == m5
if (eqTrue != true) { println("FAIL: m2==m5 expected true, got ${eqTrue}"); return () }
let eqFalse = m1 == m2
if (eqFalse != false) { println("FAIL: m1==m2 expected false, got ${eqFalse}"); return () }

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
if (colorStr != "Red") { println("FAIL: Color toString expected 'Red', got '${colorStr}'"); return () }

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
if (v3.x() != 4) { println("FAIL: Vec2 v3.x() expected 4, got ${v3.x()}"); return () }
if (v3.y() != 6) { println("FAIL: Vec2 v3.y() expected 6, got ${v3.y()}"); return () }

println("PASS: 28_enum_operators")
