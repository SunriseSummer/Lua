dofile("cangjie-tests/_testing.cj")

// Test: Numeric literal and conversion errors

expectLoadError("float missing dot",
  "let a = 3e2",
  "Float64 literal requires '.' or 'f64' suffix")

expectNoError("float exponent with f64 suffix",
  "let a = 3e2f64\nlet b = a + 1.0")

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

expectRuntimeError("uint from negative float",
  "let x = UInt64(-1.0)",
  "cannot convert negative Float64 to UInt64")

expectRuntimeError("uint from large float",
  "let x = UInt64(1e20f64)",
  "out of range")

expectRuntimeError("uint overflow in mixed add",
  "let x = 9223372036854775808u64 + 1",
  "UInt64 value out of Int64 range")

expectRuntimeError("uint overflow in mixed sub",
  "let x = 1 - 9223372036854775808u64",
  "UInt64 value out of Int64 range")

expectRuntimeError("uint overflow in mixed mul",
  "let x = 2 * 9223372036854775808u64",
  "UInt64 value out of Int64 range")

if (!__test_failed) {
    println("PASS: diagnosis/17_numeric_literal_errors")
}
