dofile("cangjie-tests/_testing.cj")

// Test: Variable scoping errors
// Tests that same-scope redefinition is caught and shadowing works.

// -- Helper: check load-time errors --
func expectLoadError(test_name: String, code: String, expected: String) {
  let result, err = load(code)
  if (result == nil) {
    let err_str = tostring(err)
    if (string.find(err_str, expected, 1, true) == nil) {
      println("FAIL: ${test_name} - expected '${expected}', got '${err_str}'")
      __test_failed = true
    }
  } else {
    println("FAIL: ${test_name} - expected a load error but code loaded successfully")
    __test_failed = true
  }
}

// -- Helper: check that code runs without error --
func expectNoError(test_name: String, code: String) {
  let result, err = load(code)
  if (result == nil) {
    println("FAIL: ${test_name} - expected success but got load error: ${tostring(err)}")
    __test_failed = true
  } else {
    let ok, rerr = pcall(result)
    if (!ok) {
      println("FAIL: ${test_name} - expected success but got runtime error: ${tostring(rerr)}")
      __test_failed = true
    }
  }
}

// -- Section: same-scope redefinition errors --
expectLoadError("let redefinition same scope",
  "let x = 1\nlet x = 2",
  "already defined in this scope")

expectLoadError("var redefinition same scope",
  "var x = 1\nvar x = 2",
  "already defined in this scope")

expectLoadError("let then var same name",
  "let x = 1\nvar x = 2",
  "already defined in this scope")

expectLoadError("var then let same name",
  "var x = 1\nlet x = 2",
  "already defined in this scope")

expectLoadError("duplicate in multi-var",
  "let a, a = 1, 2",
  "already defined in this scope")

// -- Section: shadowing should work --
expectNoError("shadow in nested block",
  "let x = 1\nif (true) { let x = 2 }")

expectNoError("shadow in function",
  "let x = 1\nfunc f(): Int64 { let x = 2; return x }")

expectNoError("shadow multi-level",
  "var z = 1\nif (true) { var z = 2\n  if (true) { var z = 3 } }")

expectNoError("same name sibling scopes",
  "if (true) { let x = 1 }\nif (true) { let x = 2 }")

if (!__test_failed) {
    println("PASS: diagnosis/03_scope_errors")
}
