dofile("cangjie-tests/_testing.cj")

// Test: Float64 literal must contain '.' character

expectLoadError("float literal without dot",
  "let x = 1e3",
  "float literal must contain '.'")

if (!__test_failed) {
    println("PASS: diagnosis/17_float_literal_errors")
}
