// Diagnosis test: type and semantic errors
// Tests for struct/class/enum/interface error detection

var passed: Int64 = 0
var total: Int64 = 0

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

func check_runtime_error(test_name: String, code: String, expected: String) {
  total = total + 1
  let chunk, err = load(code)
  if (chunk == nil) {
    println("FAIL: " + test_name)
    println("  Code failed to load: " + tostring(err))
    return ()
  }
  let ok, rerr = pcall(chunk)
  if (!ok) {
    let err_str = tostring(rerr)
    if (string.find(err_str, expected, 1, true) != nil) {
      passed = passed + 1
    } else {
      println("FAIL: " + test_name)
      println("  Expected error containing: " + expected)
      println("  Got: " + err_str)
    }
  } else {
    println("FAIL: " + test_name)
    println("  Expected a runtime error but code succeeded")
  }
}

// === Struct/Class Errors ===

// 1. Invalid member in struct body
check_load_error("invalid member in struct",
  "struct Foo { return 42 }",
  "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body")

// 2. Missing func name
check_load_error("missing func name",
  "func () { }",
  "<name> expected")

// 3. Missing closing brace for class body
check_load_error("unclosed class body",
  "class Bar { var x: Int64",
  "'}' expected")

// 4. Invalid enum body token
check_load_error("invalid enum body",
  "enum Foo { let x = 1 }",
  "expected '|', constructor name, 'func', or 'operator' in enum body")

// 5. Invalid interface body
check_load_error("invalid interface body",
  "interface Foo { var x: Int64 }",
  "expected 'func' declaration in interface body")

// === Runtime Errors ===

// 6. Calling a nil function
check_runtime_error("call nil function",
  "let f = nil\nf()",
  "attempt to call")

// 7. Arithmetic on string
check_runtime_error("arithmetic on string",
  "let x = \"hello\" - 1",
  "attempt to")

// 8. Index out of bounds on table (returns nil, no error)
// This is Lua behavior - accessing missing key returns nil
// So we test something that DOES error:

// 9. Comparison type mismatch
check_runtime_error("comparison type mismatch",
  "let x = (1 < \"hello\")",
  "attempt to compare")

// === Results ===
println("Type/semantic tests: " + tostring(passed) + "/" + tostring(total) + " passed")
if (passed == total) {
  println("PASS: diagnosis/02_type_semantic_errors")
} else {
  println("FAIL: diagnosis/02_type_semantic_errors")
}
