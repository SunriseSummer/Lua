// Test: Types and operations
// Validates integer arithmetic, float arithmetic, boolean logic, string concat,
// comparison operators, type conversions, array access, and Rune type.

// -- Section: integer arithmetic --
let a: Int64 = 10
let b: Int64 = 3
if (a + b != 13) { println("FAIL: a+b expected 13, got ${a + b}"); return () }
if (a - b != 7) { println("FAIL: a-b expected 7, got ${a - b}"); return () }
if (a * b != 30) { println("FAIL: a*b expected 30, got ${a * b}"); return () }
if (a % b != 1) { println("FAIL: a%%b expected 1, got ${a % b}"); return () }

// -- Section: float arithmetic --
let pi: Float64 = 3.14159
let r: Float64 = 5.0
let area = pi * r * r
if (tostring(area) != "78.53975") { println("FAIL: area expected 78.53975, got ${area}"); return () }

// -- Section: boolean operations --
let t: Bool = true
let f: Bool = false
if ((t && f) != false) { println("FAIL: t&&f expected false, got ${t && f}"); return () }
if ((t || f) != true) { println("FAIL: t||f expected true, got ${t || f}"); return () }
if ((!t) != false) { println("FAIL: !t expected false, got ${!t}"); return () }

// -- Section: string operations --
let s1: String = "Hello"
let s2: String = "World"
let s3 = s1 + ", " + s2 + "!"
if (s3 != "Hello, World!") { println("FAIL: s3 expected 'Hello, World!', got '${s3}'"); return () }

// -- Section: comparison operators --
if ((10 == 10) != true) { println("FAIL: 10==10 expected true"); return () }
if ((10 != 20) != true) { println("FAIL: 10!=20 expected true"); return () }
if ((10 < 20) != true) { println("FAIL: 10<20 expected true"); return () }
if ((10 > 20) != false) { println("FAIL: 10>20 expected false"); return () }
if ((10 <= 10) != true) { println("FAIL: 10<=10 expected true"); return () }
if ((10 >= 20) != false) { println("FAIL: 10>=20 expected false"); return () }

// -- Section: type conversions --
let n = tostring(42)
if (n != "42") { println("FAIL: tostring(42) expected '42', got '${n}'"); return () }
let m = tonumber("123")
if (m != 123) { println("FAIL: tonumber('123') expected 123, got ${m}"); return () }

// -- Section: array access --
let arr: Array<Int64> = [1, 2, 3, 4, 5]
if (arr[0] != 1) { println("FAIL: arr[0] expected 1, got ${arr[0]}"); return () }
if (arr[1] != 2) { println("FAIL: arr[1] expected 2, got ${arr[1]}"); return () }
if (arr.size != 5) { println("FAIL: arr.size expected 5, got ${arr.size}"); return () }

// -- Section: Rune type --
let ch: Rune = 'X'
if (tostring(ch) != "X") { println("FAIL: ch expected X, got ${ch}"); return () }

println("PASS: 04_types_operations")
