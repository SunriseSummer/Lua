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

// Higher-order function with brace lambda
func transform(arr, fn: (Int64) -> Int64) {
  var i = 0
  while (arr[i] != nil) {
    arr[i] = fn(arr[i])
    i = i + 1
  }
  return arr
}

// Named parameter with ! syntax
func greet(name: String, prefix!: String) {
  println("${prefix}, ${name}!")
}
greet("World", "Hello")

// Named parameter with default value
func power(base: Int64, exponent!: Int64 = 2): Int64 {
  var result = 1
  var i = 0
  while (i < exponent) {
    result = result * base
    i = i + 1
  }
  return result
}
println("power(3, 2) = ${power(3, 2)}")
println("power(5, 3) = ${power(5, 3)}")

// Multiple named parameters with defaults
func createPoint(x!: Int64 = 0, y!: Int64 = 0): String {
  return "(${x}, ${y})"
}
println("createPoint(3, 4) = ${createPoint(3, 4)}")
println("createPoint(1, 2) = ${createPoint(1, 2)}")

// Function with both positional and named parameters
func formatNum(value: Int64, prefix!: String = "", suffix!: String = "") {
  println("${prefix}${value}${suffix}")
}
formatNum(42, "$", " USD")
formatNum(100, "", "%")

println("PASS: 16_func_types_named_params")
