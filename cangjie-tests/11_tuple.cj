// Test: Tuple Type

// Basic tuple creation
let t1 = (1, 2, 3)
println(t1[0])  // 1
println(t1[1])  // 2
println(t1[2])  // 3

// Mixed type tuple
let t2 = (42, "hello", true, 3.14)
println(t2[0])  // 42
println(t2[1])  // hello
println(t2[2])  // true
println(t2[3])  // 3.14

// Two-element tuple (pair)
let pair = ("name", "Alice")
println(pair[0])  // name
println(pair[1])  // Alice

// Tuple as function return value
func minmax(a: Int64, b: Int64) {
  if (a < b) {
    return (a, b)
  }
  return (b, a)
}

let result = minmax(17, 5)
println("min=${result[0]} max=${result[1]}")

// Tuple with nested values
let t_inner1 = (1, 2)
let t_inner2 = (3, 4)
let nested = (t_inner1, t_inner2)
let inner1 = nested[0]
let inner2 = nested[1]
println(inner1[0])  // 1
println(inner1[1])  // 2
println(inner2[0])  // 3
println(inner2[1])  // 4

// Tuple size via __n field
let t3 = (10, 20, 30)
println(t3.__n)  // 3

println("PASS: 11_tuple")
