dofile("cangjie-tests/_testing.cj")

// Test: Rune type compile-time and runtime errors

// -- Section: Multi-character Rune literals (r'xx' / r"xx") --
expectLoadError("multi-char Rune r'hello'",
    "let a = r'hello'", "single character")

expectLoadError("multi-char Rune r\"你好\"",
    'let a = r"你好"', "single character")

// -- Section: Valid Rune assignments (should not error) --
expectNoError("r'x' to Rune", "let a: Rune = r'a'")
expectNoError("r\"x\" to Rune", 'let a: Rune = r"a"')
expectNoError("string without Rune annotation", "let a = 'hello'")

// -- Section: Rune() constructor runtime errors --
expectRuntimeError("Rune() empty string",
    "Rune('')", "cannot convert empty string")

expectRuntimeError("Rune() multi-char string",
    "Rune('ab')", "single-character string")

expectRuntimeError("Rune() invalid code point (negative)",
    "Rune(-1)", "invalid Unicode code point")

expectRuntimeError("Rune() code point too large",
    "Rune(0x110000)", "invalid Unicode code point")

// -- Section: Rune comparison with incompatible type should not crash --
expectNoError("Rune == integer comparison",
    "let r = r'A'; let b = (r == 65)")

expectNoError("Rune == string comparison",
    'let r = r\'A\'; let b = (r == "A")')

// -- Section: Empty Rune literal --
expectLoadError("empty Rune literal r''",
    "let a = r''", "empty Rune literal")

if (!__test_failed) {
    println("PASS: 12_rune_type_errors")
}
