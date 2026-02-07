dofile("cangjie-tests/_testing.cj")

// Test: Type and semantic error detection
// Tests for struct/class/enum/interface error detection

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

// -- Helper: check runtime errors --
func expectRuntimeError(test_name: String, code: String, expected: String) {
  let chunk, err = load(code)
  if (chunk == nil) {
    println("FAIL: ${test_name} - code failed to load: ${tostring(err)}")
    __test_failed = true
    return ()
  }
  let ok, rerr = pcall(chunk)
  if (!ok) {
    let err_str = tostring(rerr)
    if (string.find(err_str, expected, 1, true) == nil) {
      println("FAIL: ${test_name} - expected '${expected}', got '${err_str}'")
      __test_failed = true
    }
  } else {
    println("FAIL: ${test_name} - expected a runtime error but code succeeded")
    __test_failed = true
  }
}

// -- Section: struct/class errors --
expectLoadError("invalid member in struct",
  "struct Foo { return 42 }",
  "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body")

expectLoadError("missing func name",
  "func () { }",
  "<name> expected")

expectLoadError("unclosed class body",
  "class Bar { var x: Int64",
  "'}' expected")

// -- Section: enum/interface errors --
expectLoadError("invalid enum body",
  "enum Foo { let x = 1 }",
  "expected '|', constructor name, 'func', or 'operator' in enum body")

expectLoadError("invalid interface body",
  "interface Foo { var x: Int64 }",
  "expected 'func' declaration in interface body")

// -- Section: runtime errors --
expectRuntimeError("call nil function",
  "let f = nil\nf()",
  "attempt to call")

expectRuntimeError("arithmetic on string",
  "let x = \"hello\" - 1",
  "attempt to")

expectRuntimeError("comparison type mismatch",
  "let x = (1 < \"hello\")",
  "attempt to compare")

if (!__test_failed) {
    println("PASS: diagnosis/02_type_semantic_errors")
}
