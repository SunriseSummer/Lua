dofile("cangjie-tests/_testing.cj")

// Test: Type annotation error diagnosis

// -- Section: missing type name after colon --
expectLoadError("missing type after colon in let",
  "let x: = 42",
  "type name expected after ':'")

expectLoadError("missing type after colon in var",
  "var x: = 42",
  "type name expected after ':'")

// -- Section: valid complex type annotations should parse --
expectNoError("function type annotation",
  "let f: (Int64, Int64) -> Int64 = nil")

expectNoError("generic type annotation",
  "let a: Array<Int64> = nil")

expectNoError("function type in generic",
  "let a: Array<(Int64, Int64) -> Int64> = nil")

expectNoError("nested generic type",
  "let a: Array<Array<Int64>> = nil")

expectNoError("option type annotation",
  "let x: ?Int64 = nil")

expectNoError("function type returning generic",
  "let f: (Int64) -> Array<Int64> = nil")

// -- Section: IIFE should parse correctly --
expectNoError("basic IIFE no params",
  "let x = { => 42 }()")

expectNoError("IIFE with params",
  "let x = { a, b => a + b }(1, 2)")

expectNoError("IIFE in expression",
  "let x = { => 10 }() + { => 20 }()")

if (!__test_failed) {
  println("PASS: diagnosis/06_type_annotation_errors")
}
