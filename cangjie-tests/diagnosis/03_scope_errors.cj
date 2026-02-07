// Diagnosis test: variable scoping errors
// Tests that same-scope redefinition is caught and shadowing works.

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

// === Same scope redefinition errors ===

// 1. let redefinition in same scope
check_load_error("let redefinition same scope",
  "let x = 1\nlet x = 2",
  "already defined in this scope")

// 2. var redefinition in same scope
check_load_error("var redefinition same scope",
  "var x = 1\nvar x = 2",
  "already defined in this scope")

// 3. let then var same name
check_load_error("let then var same name",
  "let x = 1\nvar x = 2",
  "already defined in this scope")

// 4. var then let same name
check_load_error("var then let same name",
  "var x = 1\nlet x = 2",
  "already defined in this scope")

// 5. Duplicate in multi-variable declaration
check_load_error("duplicate in multi-var",
  "let a, a = 1, 2",
  "already defined in this scope")

// === Shadowing should work fine ===

// 6. Shadowing in nested block
check_no_error("shadow in nested block",
  "let x = 1\nif (true) { let x = 2 }")

// 7. Shadowing in function
check_no_error("shadow in function",
  "let x = 1\nfunc f(): Int64 { let x = 2; return x }")

// 8. Shadowing across multiple nesting levels
check_no_error("shadow multi-level",
  "var z = 1\nif (true) { var z = 2\n  if (true) { var z = 3 } }")

// 9. Same name in sibling scopes (not same scope)
check_no_error("same name sibling scopes",
  "if (true) { let x = 1 }\nif (true) { let x = 2 }")

// === Results ===
println("Diagnosis tests: " + tostring(passed) + "/" + tostring(total) + " passed")
if (passed == total) {
  println("PASS: diagnosis/03_scope_errors")
} else {
  println("FAIL: diagnosis/03_scope_errors")
}
