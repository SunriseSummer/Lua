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

if (describe(1) != "int: 1") {
  println("FAIL: describe(1) expected 'int: 1', got '" + describe(1) + "'")
  return ()
}
if (describe(1, 2) != "pair: 1,2") {
  println("FAIL: describe(1,2) expected 'pair: 1,2', got '" + describe(1, 2) + "'")
  return ()
}
if (describe(1, 2, 3) != "triple: 1,2,3") {
  println("FAIL: describe(1,2,3) expected 'triple: 1,2,3', got '" + describe(1, 2, 3) + "'")
  return ()
}

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
if (v3.x != 4 || v3.y != 6) {
  println("FAIL: v1 + v2 expected (4, 6), got " + v3.toString())
  return ()
}

// Test subtraction
let v4 = v2 - v1
if (v4.x != 2 || v4.y != 2) {
  println("FAIL: v2 - v1 expected (2, 2), got " + v4.toString())
  return ()
}

// Test multiplication
let v5 = v1 * 3
if (v5.x != 3 || v5.y != 6) {
  println("FAIL: v1 * 3 expected (3, 6), got " + v5.toString())
  return ()
}

// Test equality
if (!(v1 == v1)) {
  println("FAIL: v1 == v1 should be true")
  return ()
}
if (v1 == v2) {
  println("FAIL: v1 == v2 should be false")
  return ()
}

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
if (f3.num != 5 || f3.den != 6) {
  println("FAIL: 1/2 + 1/3 expected 5/6, got " + f3.toString())
  return ()
}

// Equivalent fractions
let f4 = Fraction(2, 4)
if (!(f1 == f4)) {
  println("FAIL: 1/2 == 2/4 should be true")
  return ()
}

// === Overloading with different scenarios ===
func area(r: Float64): Float64 {
  return 3.14159 * r * r
}

func area(w: Float64, h: Float64): Float64 {
  return w * h
}

let circle = area(5.0)
let rect = area(3.0, 4.0)

if (rect != 12.0) {
  println("FAIL: area(3.0, 4.0) expected 12.0, got " + tostring(rect))
  return ()
}

println("PASS: 20_func_overload")
