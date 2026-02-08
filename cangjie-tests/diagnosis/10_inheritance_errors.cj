dofile("cangjie-tests/_testing.cj")

// Test: Error conditions related to inheritance and type system

// -- Section: Inheriting from undefined parent --
expectRuntimeError("undefined parent class",
    "class Dog <: UnknownAnimal { init() {} }",
    "table expected")

// -- Section: Super in class without parent --
expectRuntimeError("super without parent",
    "class Foo { init() { super() } }\nlet f = Foo()",
    "super: class has no parent")

// -- Section: Type redefinition errors --
expectLoadError("class redefine as struct",
    "class Foo { var x = 0 }\nstruct Foo { var y = 0 }",
    "already defined")

expectLoadError("struct redefine as enum",
    "struct Bar { var x = 0 }\nenum Bar { | A }",
    "already defined")

// -- Section: Invalid member in class body --
expectLoadError("invalid stmt in class",
    "class Foo { return 42 }",
    "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body")

// -- Section: Invalid member in interface --
expectLoadError("var in interface",
    "interface Foo { var x: Int64 }",
    "expected 'func' declaration in interface body")

// -- Section: Missing init name --
expectLoadError("missing struct name",
    "struct { var x: Int64 }",
    "<name> expected")

// -- Section: Runtime errors with types --
expectRuntimeError("call non-function field",
    "struct Foo { var x = 10 }\nlet f = Foo()\nf.x()",
    "attempt to call")

expectRuntimeError("field access on nil",
    "let x = nil\nlet y = x.name",
    "attempt to index")

expectRuntimeError("arithmetic on struct",
    "struct Foo { var x = 0 }\nlet a = Foo()\nlet b = a + 1",
    "attempt to")

if (!__test_failed) {
    println("PASS: diagnosis/10_inheritance_errors")
}
