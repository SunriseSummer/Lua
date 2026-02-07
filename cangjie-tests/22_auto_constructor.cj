// Test: Auto-generated constructors for classes and structs
// Validates auto-constructor field assignment, no-arg defaults, and explicit init

// --- Auto constructor for class ---
class A {
  var x: Int64 = 0
  var y: Int64 = 1
}
let a = A(2, 4)
if (a.x != 2) { println("FAIL: a.x expected 2, got ${a.x}"); return () }
if (a.y != 4) { println("FAIL: a.y expected 4, got ${a.y}"); return () }

// --- Auto constructor for struct ---
struct B {
  var x: Int64 = 0
  var y: String = ""
}
let b = B(1, "hello")
if (b.x != 1) { println("FAIL: b.x expected 1, got ${b.x}"); return () }
if (b.y != "hello") { println("FAIL: b.y expected 'hello', got '${b.y}'"); return () }

// --- No args: fields remain unset (nil) ---
let c = A()
if (c.x != nil) { println("FAIL: c.x expected nil, got ${tostring(c.x)}"); return () }

// --- Class with explicit init ---
class C {
  var x: Int64
  init(v: Int64) {
    this.x = v * 2
  }
}
let d = C(5)
if (d.x != 10) { println("FAIL: d.x expected 10, got ${d.x}"); return () }

println("PASS: 22_auto_constructor")
