// Test: Variable scoping and shadowing
// Validates let/var shadowing in nested blocks and function scopes

// --- Variable shadowing in nested scopes ---
let x = 10
var innerX: Int64 = 0
if (true) {
  let x = 20
  innerX = x
}
if (innerX != 20) { println("FAIL: inner x expected 20, got ${innerX}"); return () }
if (x != 10) { println("FAIL: outer x expected 10, got ${x}"); return () }

// --- Function scope shadowing ---
let y = 100
func test(): Int64 {
  let y = 200
  return y
}
let testResult = test()
if (testResult != 200) { println("FAIL: test() expected 200, got ${testResult}"); return () }
if (y != 100) { println("FAIL: y expected 100, got ${y}"); return () }

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
if (z3 != 3) { println("FAIL: innermost z expected 3, got ${z3}"); return () }
if (z2 != 2) { println("FAIL: middle z expected 2, got ${z2}"); return () }
if (z != 1) { println("FAIL: outer z expected 1, got ${z}"); return () }

println("PASS: 24_variable_scoping")
