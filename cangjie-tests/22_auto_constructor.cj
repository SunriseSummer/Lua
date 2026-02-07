// Auto constructor for class
class A {
  var x: Int64 = 0
  var y: Int64 = 1
}
let a = A(2, 4)
println(a.x)  // 2
println(a.y)  // 4

// Auto constructor for struct
struct B {
  var x: Int64 = 0
  var y: String = ""
}
let b = B(1, "hello")
println(b.x)  // 1
println(b.y)  // hello

// No args: auto-constructor has no args to assign, fields remain unset (nil)
let c = A()
println(c.x)  // nil - no init and no args, so fields are not assigned

// Class with explicit init should still work
class C {
  var x: Int64
  init(v: Int64) {
    this.x = v * 2
  }
}
let d = C(5)
println(d.x)  // 10

println("PASS: 22_auto_constructor")
