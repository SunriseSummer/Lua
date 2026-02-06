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
println("t and f = ${t && f}")
println("t or f = ${t || f}")
println("not t = ${!t}")

// String operations
let s1: String = "Hello"
let s2: String = "World"
let s3 = s1 + ", " + s2 + "!"
println(s3)

// Comparison operators
println(10 == 10)
println(10 != 20)
println(10 < 20)
println(10 > 20)
println(10 <= 10)
println(10 >= 20)

// Type conversion
let n = tostring(42)
println(n)
let m = tonumber("123")
println(m)

// Array literal and 0-based indexing
let arr: Array<Int64> = [1, 2, 3, 4, 5]
println("arr[0] = ${arr[0]}")     // 1 (0-based)
println("arr[1] = ${arr[1]}")     // 2 (0-based)
println("arr.size = ${arr.size}") // 5

// Rune (character) type - single quotes
let ch: Rune = 'X'
println("char = ${ch}")

println("PASS: 04_types_operations")
