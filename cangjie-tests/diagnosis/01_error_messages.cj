dofile("cangjie-tests/_testing.cj")

// Test: Lexical, syntax, and semantic error messages
// Verifies that the interpreter produces correct error messages
// for various error conditions using pcall/load.

// -- Helper: check if error message contains expected substring --
func expectError(test_name: String, code: String, expected: String) {
  let ok, err = pcall(load(code))
  if (!ok) {
    let err_str = tostring(err)
    if (string.find(err_str, expected, 1, true) == nil) {
      println("FAIL: ${test_name} - expected error containing '${expected}', got '${err_str}'")
      __test_failed = true
    }
  } else {
    let ok2, err2 = pcall(err)
    if (!ok2) {
      let err_str2 = tostring(err2)
      if (string.find(err_str2, expected, 1, true) == nil) {
        println("FAIL: ${test_name} - expected error containing '${expected}', got '${err_str2}'")
        __test_failed = true
      }
    } else {
      println("FAIL: ${test_name} - expected an error but code succeeded")
      __test_failed = true
    }
  }
}

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

// -- Section: lexical errors --
expectLoadError("unfinished string",
  "let s = \"hello",
  "unfinished string")

expectLoadError("invalid escape sequence",
  "let s = \"\\q\"",
  "invalid escape sequence")

expectLoadError("malformed number",
  "let x = 0xGG",
  "malformed number")

// -- Section: syntax errors --
expectLoadError("missing closing brace for struct",
  "struct Foo { var x: Int64",
  "'}' expected")

expectLoadError("missing name after struct",
  "struct { }",
  "<name> expected")

expectLoadError("missing parens in if",
  "if true { }",
  "'(' expected")

expectLoadError("missing parens in while",
  "while true { }",
  "'(' expected")

expectLoadError("missing parens in for",
  "for i in 1..10 { }",
  "'(' expected")

expectLoadError("missing arrow in match",
  "match (1) { case 1 println(\"x\") }",
  "'=>' expected")

expectLoadError("missing parens in match",
  "match 1 { case 1 => println(\"x\") }",
  "'(' expected")

// -- Section: semantic errors --
expectLoadError("break outside loop",
  "break",
  "break outside loop")

expectLoadError("continue outside loop",
  "continue",
  "continue outside loop")

expectLoadError("assign to let variable",
  "let x = 10\nx = 20",
  "attempt to assign to const variable")

expectLoadError("empty type annotation",
  "let x: = 10",
  "type name expected after ':'")

expectLoadError("let without initializer",
  "let x: Int64",
  "requires an initializer")

if (!__test_failed) {
    println("PASS: diagnosis/01_error_messages")
}
