dofile("cangjie-tests/_testing.cj")

// Test: Numeric literal and conversion errors

expectLoadError("float missing dot",
  "let a = 3e2",
  "Float64 literal requires '.' or 'f64' suffix")

expectLoadError("int suffix with dot",
  "let a = 1.2i64",
  "integer literal cannot have decimal point or exponent")

expectLoadError("uint suffix with exp",
  "let a = 1e2u64",
  "integer literal cannot have decimal point or exponent")

expectLoadError("uint suffix with dot",
  "let a = 1.0u64",
  "integer literal cannot have decimal point or exponent")

expectLoadError("bad suffix",
  "let a = 1i63",
  "malformed number")

expectRuntimeError("uint from negative int",
  "let x = UInt64(-1)",
  "cannot convert negative Int64 to UInt64")

expectRuntimeError("uint from negative string",
  "let x = UInt64(\"-1\")",
  "cannot convert negative Int64 to UInt64")

if (!__test_failed) {
    println("PASS: diagnosis/17_numeric_literal_errors")
}
