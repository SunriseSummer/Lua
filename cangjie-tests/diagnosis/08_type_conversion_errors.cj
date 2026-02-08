dofile("cangjie-tests/_testing.cj")

// Test: Type conversion error cases

// -- Section: Int64() error cases --
expectRuntimeError("Int64(nil)", "let x = Int64(nil)", "cannot convert")
expectRuntimeError("Int64 bad string", "let x = Int64(\"abc\")", "cannot convert")
expectRuntimeError("Int64 empty string", "let x = Int64(\"\")", "cannot convert")

// -- Section: Float64() error cases --
expectRuntimeError("Float64(nil)", "let x = Float64(nil)", "cannot convert")
expectRuntimeError("Float64 bad string", "let x = Float64(\"abc\")", "cannot convert")
expectRuntimeError("Float64(true)", "let x = Float64(true)", "cannot convert")

// -- Section: Bool() error cases --
expectRuntimeError("Bool(nil)", "let x = Bool(nil)", "cannot convert")
expectRuntimeError("Bool(42)", "let x = Bool(42)", "cannot convert")
expectRuntimeError("Bool bad string", "let x = Bool(\"yes\")", "cannot convert")

// -- Section: Rune() error cases --
expectRuntimeError("Rune negative", "let x = Rune(-1)", "invalid Unicode")
expectRuntimeError("Rune too large", "let x = Rune(0x110000)", "invalid Unicode")
expectRuntimeError("Rune empty string", 'let x = Rune("")', "cannot convert empty string")
expectRuntimeError("Rune multi-char", "let x = Rune(\"hello\")", "single-character string")
expectRuntimeError("Rune multi-char unicode", 'let x = Rune("你好")', "single-character string")

if (!__test_failed) {
    println("PASS: 08_type_conversion_errors")
}
