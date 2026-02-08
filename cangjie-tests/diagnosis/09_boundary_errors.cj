dofile("cangjie-tests/_testing.cj")

// Test: Additional error diagnosis cases

// --- Section: Assignment to let variable ---
expectLoadError("let reassign", "let x = 10; x = 20", "immutable variable")

// --- Section: break outside loop ---
expectLoadError("break outside loop", "break", "break outside loop")

// --- Section: continue outside loop ---
expectLoadError("continue outside loop", "continue", "continue outside loop")

// --- Section: let without initializer ---
expectLoadError("let no init", "let x", "requires an initializer")

// --- Section: Duplicate let in same scope ---
expectLoadError("duplicate let", "let a = 1; let a = 2", "already defined")

// --- Section: Duplicate var in same scope ---
expectLoadError("duplicate var", "var b = 1; var b = 2", "already defined")

// --- Section: Missing closing brace for if ---
expectLoadError("if no close brace", "if (true) { var x = 1", "'}' expected")

// --- Section: Missing condition parentheses for while ---
expectLoadError("while no parens", "while true { }", "'(' expected")

// --- Section: Invalid struct member ---
expectLoadError("struct invalid member", "struct S { println(1) }", "expected")

// --- Section: getOrThrow on None ---
expectRuntimeError("None getOrThrow", "let x = None; x.getOrThrow()", "Option is None")

// --- Section: Calling non-function ---
expectRuntimeError("call non-function", "let x = 42; x()", "attempt to call")

// --- Section: Duplicate function definition ---
// Functions can be overloaded by arity, but same arity should be ok (redefined)
expectNoError("func redefined same arity", "func f(x) { return 1 }; func f(x) { return 2 }; let r = f(1)")

if (!__test_failed) {
    println("PASS: 09_boundary_errors")
}
