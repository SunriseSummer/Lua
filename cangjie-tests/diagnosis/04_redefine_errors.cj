// Diagnosis test: type redefinition errors
// Tests that same-scope type redefinition is caught.

var passed: Int64 = 0
var total: Int64 = 0

// Helper: check that a load-time syntax/parse error contains expected message
func check_load_error(test_name: String, code: String, expected: String) {
  total = total + 1
  let result, err = load(code)
  if (result == nil) {
    let err_str = tostring(err)
    if (string.find(err_str, expected, 1, true) != nil) {
      passed = passed + 1
    } else {
      println("FAIL: " + test_name)
      println("  Expected error containing: " + expected)
      println("  Got: " + err_str)
    }
  } else {
    println("FAIL: " + test_name)
    println("  Expected a load error but code loaded successfully")
  }
}

// Helper: check that code runs without error
func check_no_error(test_name: String, code: String) {
  total = total + 1
  let result, err = load(code)
  if (result == nil) {
    println("FAIL: " + test_name)
    println("  Expected success but got load error: " + tostring(err))
  } else {
    let ok, rerr = pcall(result)
    if (ok) {
      passed = passed + 1
    } else {
      println("FAIL: " + test_name)
      println("  Expected success but got runtime error: " + tostring(rerr))
    }
  }
}

// === Same-scope type redefinition errors ===

// 1. Struct redefinition
check_load_error("struct redefinition",
  "struct Point { var x: Int64 = 0 }\nstruct Point { var y: Int64 = 0 }",
  "already defined in this scope")

// 2. Class redefinition
check_load_error("class redefinition",
  "class Foo { var x: Int64 = 0 }\nclass Foo { var y: Int64 = 0 }",
  "already defined in this scope")

// 3. Enum redefinition
check_load_error("enum redefinition",
  "enum Color { | Red | Green }\nenum Color { | Blue | Yellow }",
  "already defined in this scope")

// 4. Interface redefinition
check_load_error("interface redefinition",
  "interface Drawable { func draw(): Unit }\ninterface Drawable { func paint(): Unit }",
  "already defined in this scope")

// 5. Different types with same name (struct then class)
check_load_error("struct then class same name",
  "struct Foo { var x: Int64 = 0 }\nclass Foo { var y: Int64 = 0 }",
  "already defined in this scope")

// 6. Different types with same name (enum then struct)
check_load_error("enum then struct same name",
  "enum Bar { | A | B }\nstruct Bar { var x: Int64 = 0 }",
  "already defined in this scope")

// 7. Different types with same name (interface then enum)
check_load_error("interface then enum same name",
  "interface Baz { func f(): Unit }\nenum Baz { | X | Y }",
  "already defined in this scope")

// === Case sensitivity: different cases are different names ===

// 8. Different case names are OK
check_no_error("different case names",
  "struct Point { var x: Int64 = 0 }\nstruct point { var y: Int64 = 0 }")

// === Different scopes allow shadowing ===

// 9. Single struct definition (no conflict)
check_no_error("single struct no conflict",
  "struct Alpha { var x: Int64 = 0 }")

// 10. Single enum definition (no conflict)
check_no_error("single enum no conflict",
  "enum Direction { | North | South }")

// === Results ===
println("Diagnosis tests: " + tostring(passed) + "/" + tostring(total) + " passed")
if (passed == total) {
  println("PASS: diagnosis/04_redefine_errors")
} else {
  println("FAIL: diagnosis/04_redefine_errors")
}
