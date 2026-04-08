dofile("cangjie-tests/_testing.cj")

// Test: Lexical, syntax, and semantic error messages
// Verifies that the interpreter produces correct error messages
// for various error conditions using pcall/load.

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
  "attempt to assign to immutable variable")

expectLoadError("empty type annotation",
  "let x: = 10",
  "type name expected after ':'")

expectLoadError("let without initializer",
  "let x: Int64",
  "requires an initializer")

expectRuntimeError("string concat with ..",
  "let s = \"a\" .. \"b\"",
  "only supports range literals")

if (!__test_failed) {
    println("PASS: diagnosis/01_error_messages")
}
