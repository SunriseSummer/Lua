dofile("cangjie-tests/_testing.cj")

// Test: Rune type compile-time errors

// -- Section: Multi-character Rune literals (r'xx' / r"xx") --
expectLoadError("multi-char Rune r'hello'",
    "let a = r'hello'", "single character")

expectLoadError("multi-char Rune r\"你好\"",
    'let a = r"你好"', "single character")

// -- Section: Valid Rune assignments (should not error) --
expectNoError("r'x' to Rune", "let a: Rune = r'a'")
expectNoError("r\"x\" to Rune", 'let a: Rune = r"a"')
expectNoError("string without Rune annotation", "let a = 'hello'")

if (!__test_failed) {
    println("PASS: 12_rune_type_errors")
}
