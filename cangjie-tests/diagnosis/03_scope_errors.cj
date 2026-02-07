dofile("cangjie-tests/_testing.cj")

// Test: Variable scoping errors
// Tests that same-scope redefinition is caught and shadowing works.

// -- Section: same-scope redefinition errors --
expectLoadError("let redefinition same scope",
  "let x = 1\nlet x = 2",
  "already defined in this scope")

expectLoadError("var redefinition same scope",
  "var x = 1\nvar x = 2",
  "already defined in this scope")

expectLoadError("let then var same name",
  "let x = 1\nvar x = 2",
  "already defined in this scope")

expectLoadError("var then let same name",
  "var x = 1\nlet x = 2",
  "already defined in this scope")

expectLoadError("duplicate in multi-var",
  "let a, a = 1, 2",
  "already defined in this scope")

// -- Section: shadowing should work --
expectNoError("shadow in nested block",
  "let x = 1\nif (true) { let x = 2 }")

expectNoError("shadow in function",
  "let x = 1\nfunc f(): Int64 { let x = 2; return x }")

expectNoError("shadow multi-level",
  "var z = 1\nif (true) { var z = 2\n  if (true) { var z = 3 } }")

expectNoError("same name sibling scopes",
  "if (true) { let x = 1 }\nif (true) { let x = 2 }")

if (!__test_failed) {
    println("PASS: diagnosis/03_scope_errors")
}
