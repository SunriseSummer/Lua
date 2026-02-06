// Test: Types and operations

// Integer operations
let a: Int64 = 10
let b: Int64 = 3
println("a + b = ${a + b}")
println("a - b = ${a - b}")
println("a * b = ${a * b}")
println("a % b = ${a % b}")

// Float operations
let pi: Float64 = 3.14159
let r: Float64 = 5.0
let area = pi * r * r
println("area = ${area}")

// Boolean operations
let t: Bool = true
let f: Bool = false
println("t and f = ${t and f}")
println("t or f = ${t or f}")
println("not t = ${not t}")

// String operations
let s1: String = "Hello"
let s2: String = "World"
let s3 = s1 .. ", " .. s2 .. "!"
println(s3)

// String length
println("s1.size = ${#s1}")

// Comparison operators
println(10 == 10)
println(10 != 20)
println(10 < 20)
println(10 > 20)
println(10 <= 10)
println(10 >= 20)

// Nil check
let x = nil
if (x == nil) {
  println("x is nil")
}

// Type conversion
let n = tostring(42)
println(n)
let m = tonumber("123")
println(m)

// Array literal and indexing
let arr: Array<Int64> = [1, 2, 3, 4, 5]
println("arr[1] = ${arr[1]}")
println("arr.size = ${arr.size}")

// Rune (character) type
let ch: Rune = "X"
println("char = ${ch}")

// Unit type (represented as nil)
let u = nil
println("unit = ${u}")

println("PASS: 04_types_operations")
