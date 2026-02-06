// Test: Function types and named parameters

// Function type annotation in parameter
func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 {
  return fn(a, b)
}

func add(a: Int64, b: Int64): Int64 {
  return a + b
}

func sub(a: Int64, b: Int64): Int64 {
  return a - b
}

println("apply(add, 3, 4) = ${apply(add, 3, 4)}")
println("apply(sub, 10, 3) = ${apply(sub, 10, 3)}")

// Lambda expression passed directly as function type parameter
println("apply(lambda, 6, 7) = ${apply({ x, y => x * y }, 6, 7)}")
println("apply(lambda, 10, 3) = ${apply({ a, b => a - b }, 10, 3)}")

// Higher-order function accepting lambda with type annotation
func mapInt(arr, fn: (Int64) -> Int64) {
  let result = {}
  var i = 1
  while (arr[i] != nil) {
    result[i] = fn(arr[i])
    i = i + 1
  }
  return result
}

let nums = {1, 2, 3, 4, 5}
let doubled = mapInt(nums, { x => x * 2 })
print("doubled: ")
var i = 1
while (doubled[i] != nil) {
  print("${doubled[i]} ")
  i = i + 1
}
println()

// Function as return value with type annotation
func makeOp(op: String): (Int64, Int64) -> Int64 {
  if (op == "add") {
    return add
  }
  return sub
}

let addOp = makeOp("add")
let subOp = makeOp("sub")
println("addOp(5, 3) = ${addOp(5, 3)}")
println("subOp(5, 3) = ${subOp(5, 3)}")

// Named parameter with ! syntax
func greet(name: String, prefix!: String) {
  println("${prefix}, ${name}!")
}
greet("World", "Hello")

// Named parameter with default value - omitting argument
func power(base: Int64, exponent!: Int64 = 2): Int64 {
  var result = 1
  var i = 0
  while (i < exponent) {
    result = result * base
    i = i + 1
  }
  return result
}
println("power(3) = ${power(3)}")        // uses default exponent=2 → 9
println("power(3, 2) = ${power(3, 2)}")  // explicit exponent=2 → 9
println("power(3, 3) = ${power(3, 3)}")  // explicit exponent=3 → 27
println("power(5) = ${power(5)}")        // uses default exponent=2 → 25

// Multiple named parameters with defaults
func createPoint(x!: Int64 = 0, y!: Int64 = 0): String {
  return "(${x}, ${y})"
}
println("createPoint() = ${createPoint()}")        // (0, 0) - both defaults
println("createPoint(3) = ${createPoint(3)}")      // (3, 0) - y defaults
println("createPoint(3, 4) = ${createPoint(3, 4)}") // (3, 4) - no defaults

// Function with both positional and named parameters with defaults
func formatNum(value: Int64, prefix!: String = "", suffix!: String = "") {
  println("${prefix}${value}${suffix}")
}
formatNum(42, "$", " USD")
formatNum(100, "", "%")
formatNum(42)              // uses both defaults: "42"

// String default value
func hello(name!: String = "World") {
  println("Hello, ${name}!")
}
hello()       // uses default → Hello, World!
hello("Lua")  // explicit → Hello, Lua!

println("PASS: 16_func_types_named_params")
