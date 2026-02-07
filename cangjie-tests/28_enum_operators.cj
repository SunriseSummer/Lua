// Test: Enum Operator Overloading

// Enum with operator + overloading
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

// Test + operator
let m1 = Yuan(100)
let m2 = Yuan(200)
let m3 = m1 + m2
println("100 + 200 = " + tostring(m3.value()))

// Test - operator
let m4 = m3 - m1
println("300 - 100 = " + tostring(m4.value()))

// Test == operator
let m5 = Yuan(200)
println("m2 == m5: " + tostring(m2 == m5))
println("m1 == m2: " + tostring(m1 == m2))

// Enum with toString operator
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
println("Color: " + tostring(c))

// Enum with multiple operators and methods combined
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
println("(1,2) + (3,4) = (" + tostring(v3.x()) + "," + tostring(v3.y()) + ")")

println("PASS: 28_enum_operators")
