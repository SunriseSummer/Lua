dofile("cangjie-tests/_testing.cj")

// Test: Function overloading and operator func overloading

// === Basic function overloading ===
func describe(a: Int64): String {
  return "int: " + tostring(a)
}

func describe(a: Int64, b: Int64): String {
  return "pair: " + tostring(a) + "," + tostring(b)
}

func describe(a: Int64, b: Int64, c: Int64): String {
  return "triple: " + tostring(a) + "," + tostring(b) + "," + tostring(c)
}

expectEq(describe(1), "int: 1", "describe(1)")
expectEq(describe(1, 2), "pair: 1,2", "describe(1,2)")
expectEq(describe(1, 2, 3), "triple: 1,2,3", "describe(1,2,3)")

// === Operator func overloading ===
struct Vector2D {
  var x: Int64
  var y: Int64

  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
  }

  operator func +(other: Vector2D): Vector2D {
    return Vector2D(x + other.x, y + other.y)
  }

  operator func -(other: Vector2D): Vector2D {
    return Vector2D(x - other.x, y - other.y)
  }

  operator func *(scalar: Int64): Vector2D {
    return Vector2D(x * scalar, y * scalar)
  }

  operator func ==(other: Vector2D): Bool {
    return x == other.x && y == other.y
  }

  func toString(): String {
    return "(${x}, ${y})"
  }
}

let v1 = Vector2D(1, 2)
let v2 = Vector2D(3, 4)

// Test addition
let v3 = v1 + v2
expectEq(v3.toString(), "(4, 6)", "v1 + v2")

// Test subtraction
let v4 = v2 - v1
expectEq(v4.toString(), "(2, 2)", "v2 - v1")

// Test multiplication
let v5 = v1 * 3
expectEq(v5.toString(), "(3, 6)", "v1 * 3")

// Test equality
expectTrue(v1 == v1, "v1 == v1")
expectFalse(v1 == v2, "v1 == v2 should be false")

// === Operator overloading with toString ===
struct Fraction {
  var num: Int64
  var den: Int64

  init(n: Int64, d: Int64) {
    this.num = n
    this.den = d
  }

  operator func +(other: Fraction): Fraction {
    return Fraction(num * other.den + other.num * den, den * other.den)
  }

  operator func ==(other: Fraction): Bool {
    return num * other.den == other.num * den
  }

  func toString(): String {
    return tostring(num) + "/" + tostring(den)
  }
}

let f1 = Fraction(1, 2)
let f2 = Fraction(1, 3)
let f3 = f1 + f2
expectEq(f3.toString(), "5/6", "1/2 + 1/3")

// Equivalent fractions
let f4 = Fraction(2, 4)
expectTrue(f1 == f4, "1/2 == 2/4")

// === Overloading with different scenarios ===
func area(r: Float64): Float64 {
  return 3.14159 * r * r
}

func area(w: Float64, h: Float64): Float64 {
  return w * h
}

let circle = area(5.0)
let rect = area(3.0, 4.0)

expectEq(rect, 12.0, "area(3.0, 4.0)")

if (!__test_failed) {
    println("PASS: 20_func_overload")
}
