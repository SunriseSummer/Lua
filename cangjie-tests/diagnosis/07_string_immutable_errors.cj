dofile("cangjie-tests/_testing.cj")

// Test: String and immutability error diagnostics

// --- Section: immutable variable error message ---
expectLoadError("let variable reassignment",
    "let x = 10\nx = 20",
    "attempt to assign to immutable variable")

expectLoadError("let string reassignment",
    "let s = \"hello\"\ns = \"world\"",
    "attempt to assign to immutable variable")

// --- Section: string index out of range ---
expectRuntimeError("string index negative",
    "let s = \"hello\"\nlet c = s[-1]",
    "out of range")

expectRuntimeError("string index too large",
    "let s = \"hello\"\nlet c = s[5]",
    "out of range")

expectRuntimeError("string index on empty",
    "let s = \"\"\nlet c = s[0]",
    "out of range")

// --- Section: string immutability ---
expectRuntimeError("string newindex",
    "let s = \"hello\"\ns[0] = \"H\"",
    "immutable")

// --- Section: var still allows reassignment ---
expectNoError("var variable reassignment",
    "var x = 10\nx = 20")

expectNoError("var string reassignment",
    "var s = \"hello\"\ns = \"world\"")

// --- Section: valid string operations ---
expectNoError("string index valid",
    "let s = \"hello\"\nlet c = s[0]\nlet n = s.size")

expectNoError("string slice valid",
    "let s = \"hello\"\nlet sub = s[0..3]")

if (!__test_failed) {
    println("PASS: diagnosis/07_string_immutable_errors")
}
