dofile("cangjie-tests/_testing.cj")

// Test: Variable scoping and shadowing
// Validates let/var shadowing in nested blocks and function scopes

// --- Variable shadowing in nested scopes ---
let x = 10
var innerX: Int64 = 0
if (true) {
  let x = 20
  innerX = x
}
expectEq(innerX, 20, "inner x")
expectEq(x, 10, "outer x")

// --- Function scope shadowing ---
let y = 100
func test(): Int64 {
  let y = 200
  return y
}
let testResult = test()
expectEq(testResult, 200, "test()")
expectEq(y, 100, "y after test()")

// --- Nested block shadowing ---
var z = 1
var z3: Int64 = 0
var z2: Int64 = 0
if (true) {
  var z = 2
  if (true) {
    var z = 3
    z3 = z
  }
  z2 = z
}
expectEq(z3, 3, "innermost z")
expectEq(z2, 2, "middle z")
expectEq(z, 1, "outer z")

if (!__test_failed) {
    println("PASS: 24_variable_scoping")
}
