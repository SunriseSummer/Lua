// Diagnosis test: lexical errors
// This test verifies that the interpreter produces correct error messages
// for various lexical/syntax/semantic error conditions.
//
// Each test case uses pcall to catch errors and validates the error message.

var passed: Int64 = 0
var total: Int64 = 0

// Helper: check if error message contains expected substring
func check_error(test_name: String, code: String, expected: String) {
  total = total + 1
  let ok, err = pcall(load(code))
  if (!ok) {
    // load itself may fail (syntax error)
    let err_str = tostring(err)
    if (string.find(err_str, expected, 1, true) != nil) {
      passed = passed + 1
    } else {
      println("FAIL: " + test_name)
      println("  Expected error containing: " + expected)
      println("  Got: " + err_str)
    }
  } else {
    // load succeeded, but maybe pcall on execution fails
    let ok2, err2 = pcall(err)
    if (!ok2) {
      let err_str2 = tostring(err2)
      if (string.find(err_str2, expected, 1, true) != nil) {
        passed = passed + 1
      } else {
        println("FAIL: " + test_name)
        println("  Expected error containing: " + expected)
        println("  Got: " + err_str2)
      }
    } else {
      println("FAIL: " + test_name)
      println("  Expected an error but code succeeded")
    }
  }
}

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

// === Lexical Errors ===

// 1. Unfinished string
check_load_error("unfinished string",
  "let s = \"hello",
  "unfinished string")

// 2. Invalid escape sequence
check_load_error("invalid escape sequence",
  "let s = \"\\q\"",
  "invalid escape sequence")

// 3. Malformed number
check_load_error("malformed number",
  "let x = 0xGG",
  "malformed number")

// === Syntax Errors ===

// 4. Missing closing brace
check_load_error("missing closing brace for struct",
  "struct Foo { var x: Int64",
  "'}' expected")

// 5. Missing name after struct
check_load_error("missing name after struct",
  "struct { }",
  "<name> expected")

// 6. Missing parentheses around if condition
check_load_error("missing parens in if",
  "if true { }",
  "'(' expected")

// 7. Missing parentheses around while condition
check_load_error("missing parens in while",
  "while true { }",
  "'(' expected")

// 8. Missing parentheses around for
check_load_error("missing parens in for",
  "for i in 1..10 { }",
  "'(' expected")

// 9. Missing arrow in match case
check_load_error("missing arrow in match",
  "match (1) { case 1 println(\"x\") }",
  "'=>' expected")

// 10. Missing parentheses in match
check_load_error("missing parens in match",
  "match 1 { case 1 => println(\"x\") }",
  "'(' expected")

// === Semantic Errors ===

// 11. Break outside loop
check_load_error("break outside loop",
  "break",
  "break outside loop")

// 12. Continue outside loop
check_load_error("continue outside loop",
  "continue",
  "continue outside loop")

// 13. Assignment to const variable (let)
check_load_error("assign to let variable",
  "let x = 10\nx = 20",
  "attempt to assign to const variable")

// 14. Empty type annotation
check_load_error("empty type annotation",
  "let x: = 10",
  "type name expected after ':'")

// 15. let without initializer
check_load_error("let without initializer",
  "let x: Int64",
  "requires an initializer")

// === Results ===
println("Diagnosis tests: " + tostring(passed) + "/" + tostring(total) + " passed")
if (passed == total) {
  println("PASS: diagnosis/01_error_messages")
} else {
  println("FAIL: diagnosis/01_error_messages")
}
