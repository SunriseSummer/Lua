dofile("cangjie-tests/_testing.cj")

// Test: Rune type compile-time errors

// -- Section: Multi-character Rune literals (r'xx' / r"xx") --
expectLoadError("multi-char Rune r'hello'",
    "let a = r'hello'", "single character")

expectLoadError("multi-char Rune r\"你好\"",
    'let a = r"你好"', "single character")

// -- Section: String literal assigned to Rune type --
expectLoadError("string 'x' to Rune",
    "let a: Rune = 'x'", "cannot assign String")

expectLoadError("string \"x\" to Rune",
    'let a: Rune = "x"', "cannot assign String")

expectLoadError("string '0' to Rune",
    "let a: Rune = '0'", "cannot assign String")

expectLoadError("var string to Rune",
    "var a: Rune = 'x'", "cannot assign String")

// -- Section: Valid Rune assignments (should not error) --
expectNoError("r'x' to Rune", "let a: Rune = r'a'")
expectNoError("r\"x\" to Rune", 'let a: Rune = r"a"')
expectNoError("integer to Rune", "let a: Rune = 65")
expectNoError("string without Rune annotation", "let a = 'hello'")

if (!__test_failed) {
    println("PASS: 12_rune_type_errors")
}
