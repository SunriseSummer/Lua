dofile("cangjie-tests/_testing.cj")

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

expectEq(apply(add, 3, 4), 7, "apply add")
expectEq(apply(sub, 10, 3), 7, "apply sub")

// Lambda expression passed directly as function type parameter
expectEq(apply({ x, y => x * y }, 6, 7), 42, "apply lambda multiply")
expectEq(apply({ a, b => a - b }, 10, 3), 7, "apply lambda subtract")

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
expectEq(doubled[1], 2, "mapInt doubled[1]")
expectEq(doubled[2], 4, "mapInt doubled[2]")
expectEq(doubled[3], 6, "mapInt doubled[3]")
expectEq(doubled[4], 8, "mapInt doubled[4]")
expectEq(doubled[5], 10, "mapInt doubled[5]")

// Function as return value with type annotation
func makeOp(op: String): (Int64, Int64) -> Int64 {
  if (op == "add") {
    return add
  }
  return sub
}

let addOp = makeOp("add")
let subOp = makeOp("sub")
expectEq(addOp(5, 3), 8, "addOp(5, 3)")
expectEq(subOp(5, 3), 2, "subOp(5, 3)")

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
expectEq(power(3), 9, "power(3)")
expectEq(power(3, 2), 9, "power(3,2)")
expectEq(power(3, 3), 27, "power(3,3)")
expectEq(power(5), 25, "power(5)")

// Multiple named parameters with defaults
func createPoint(x!: Int64 = 0, y!: Int64 = 0): String {
  return "(${x}, ${y})"
}
expectEq(createPoint(), "(0, 0)", "createPoint()")
expectEq(createPoint(3), "(3, 0)", "createPoint(3)")
expectEq(createPoint(3, 4), "(3, 4)", "createPoint(3, 4)")

// Function with both positional and named parameters with defaults
func formatNum(value: Int64, prefix!: String = "", suffix!: String = "") {
  println("${prefix}${value}${suffix}")
}
formatNum(42, "$", " USD")
formatNum(100, "", "%")
formatNum(42)

// String default value
func hello(name!: String = "World") {
  println("Hello, ${name}!")
}
hello()
hello("Lua")

if (!__test_failed) {
    println("PASS: 16_func_types_named_params")
}
