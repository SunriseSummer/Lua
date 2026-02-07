dofile("cangjie-tests/_testing.cj")

// Test: Type and semantic error detection
// Tests for struct/class/enum/interface error detection

// -- Section: struct/class errors --
expectLoadError("invalid member in struct",
  "struct Foo { return 42 }",
  "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body")

expectLoadError("missing func name",
  "func () { }",
  "<name> expected")

expectLoadError("unclosed class body",
  "class Bar { var x: Int64",
  "'}' expected")

// -- Section: enum/interface errors --
expectLoadError("invalid enum body",
  "enum Foo { let x = 1 }",
  "expected '|', constructor name, 'func', or 'operator' in enum body")

expectLoadError("invalid interface body",
  "interface Foo { var x: Int64 }",
  "expected 'func' declaration in interface body")

// -- Section: runtime errors --
expectRuntimeError("call nil function",
  "let f = nil\nf()",
  "attempt to call")

expectRuntimeError("arithmetic on string",
  "let x = \"hello\" - 1",
  "attempt to")

expectRuntimeError("comparison type mismatch",
  "let x = (1 < \"hello\")",
  "attempt to compare")

if (!__test_failed) {
    println("PASS: diagnosis/02_type_semantic_errors")
}
