dofile("cangjie-tests/_testing.cj")

// Test: Advanced error detection and diagnostics

// --- Syntax errors in complex constructs ---

expectLoadError("missing => in match case",
    "match (1) { case 1 return 0 }",
    "'=>' expected")

expectLoadError("missing ) in match",
    "match (1 { case 1 => return 0 }",
    "')' expected")

expectLoadError("missing { in match",
    "match (1) case 1 => return 0 }",
    "'{' expected")

// --- Let/var semantic errors ---

expectLoadError("let without init",
    "let x: Int64",
    "requires an initializer")

expectLoadError("reassign to let",
    "let x = 10\nx = 20",
    "attempt to assign to const variable")

// --- Struct/class errors ---

expectLoadError("missing name for struct",
    "struct { var x: Int64 }",
    "<name> expected")

expectLoadError("invalid member in class",
    "class Foo { return 42 }",
    "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body")

// --- Enum errors ---

expectLoadError("invalid member in enum",
    "enum Foo { let x = 1 }",
    "expected '|', constructor name, 'func', or 'operator' in enum body")

// --- Interface errors ---

expectLoadError("invalid member in interface",
    "interface Foo { var x: Int64 }",
    "expected 'func' declaration in interface body")

// --- Runtime type errors ---

expectRuntimeError("call nil value",
    "let f = nil\nf()",
    "attempt to call")

expectRuntimeError("arithmetic on bool",
    "let x = true + 1",
    "attempt to")

expectRuntimeError("index nil value",
    "let x = nil\nlet y = x[0]",
    "attempt to index")

// --- Break/continue outside loop ---

expectLoadError("break outside loop",
    "break",
    "break outside loop")

expectLoadError("continue outside loop",
    "continue",
    "continue outside loop")

// --- Empty type annotation ---

expectLoadError("empty type after colon",
    "let x: = 10",
    "type name expected after ':'")

// --- Duplicate type definitions ---

expectLoadError("duplicate struct name",
    "struct Foo { var x = 0; Foo() {} }\nstruct Foo { var y = 0; Foo() {} }",
    "already defined")

expectLoadError("duplicate enum name",
    "enum Color { | Red }\nenum Color { | Blue }",
    "already defined")

// --- Variable redefinition in same scope ---

expectLoadError("duplicate let in same scope",
    "let x = 1\nlet x = 2",
    "already defined")

expectLoadError("duplicate var in same scope",
    "var x = 1\nvar x = 2",
    "already defined")

// --- Malformed numbers ---

expectLoadError("malformed hex number",
    "let x = 0xZZ",
    "malformed number")

// --- Unfinished string ---

expectLoadError("unfinished string literal",
    "let s = \"hello",
    "unfinished string")

// --- Invalid escape ---

expectLoadError("invalid escape in string",
    "let s = \"\\q\"",
    "invalid escape sequence")

if (!__test_failed) {
    println("PASS: diagnosis/05_advanced_errors")
}
