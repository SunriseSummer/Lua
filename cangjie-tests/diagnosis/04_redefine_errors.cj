dofile("cangjie-tests/_testing.cj")

// Test: Type redefinition errors
// Tests that same-scope type redefinition is caught.

// -- Section: same-scope type redefinition errors --
expectLoadError("struct redefinition",
  "struct Point { var x: Int64 = 0 }\nstruct Point { var y: Int64 = 0 }",
  "already defined in this scope")

expectLoadError("class redefinition",
  "class Foo { var x: Int64 = 0 }\nclass Foo { var y: Int64 = 0 }",
  "already defined in this scope")

expectLoadError("enum redefinition",
  "enum Color { | Red | Green }\nenum Color { | Blue | Yellow }",
  "already defined in this scope")

expectLoadError("interface redefinition",
  "interface Drawable { func draw(): Unit }\ninterface Drawable { func paint(): Unit }",
  "already defined in this scope")

// -- Section: cross-type redefinition errors --
expectLoadError("struct then class same name",
  "struct Foo { var x: Int64 = 0 }\nclass Foo { var y: Int64 = 0 }",
  "already defined in this scope")

expectLoadError("enum then struct same name",
  "enum Bar { | A | B }\nstruct Bar { var x: Int64 = 0 }",
  "already defined in this scope")

expectLoadError("interface then enum same name",
  "interface Baz { func f(): Unit }\nenum Baz { | X | Y }",
  "already defined in this scope")

// -- Section: case sensitivity and valid definitions --
expectNoError("different case names",
  "struct Point { var x: Int64 = 0 }\nstruct point { var y: Int64 = 0 }")

expectNoError("single struct no conflict",
  "struct Alpha { var x: Int64 = 0 }")

expectNoError("single enum no conflict",
  "enum Direction { | North | South }")

if (!__test_failed) {
    println("PASS: diagnosis/04_redefine_errors")
}
