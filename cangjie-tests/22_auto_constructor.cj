dofile("cangjie-tests/_testing.cj")

// Test: Auto-generated constructors for classes and structs
// Validates auto-constructor field assignment, no-arg defaults, and explicit init

// --- Auto constructor for class ---
class A {
  var x: Int64 = 0
  var y: Int64 = 1
}
let a = A(2, 4)
expectEq(a.x, 2, "a.x")
expectEq(a.y, 4, "a.y")

// --- Auto constructor for struct ---
struct B {
  var x: Int64 = 0
  var y: String = ""
}
let b = B(1, "hello")
expectEq(b.x, 1, "b.x")
expectEq(b.y, "hello", "b.y")

// --- No args: fields remain unset (nil) ---
let c = A()
expectNil(c.x, "c.x")

// --- Class with explicit init ---
class C {
  var x: Int64
  init(v: Int64) {
    this.x = v * 2
  }
}
let d = C(5)
expectEq(d.x, 10, "d.x")

if (!__test_failed) {
    println("PASS: 22_auto_constructor")
}
