// Test: String interpolation

let name = "Cangjie"
let version = 1

// Basic interpolation
println("Hello, ${name}!")  // Hello, Cangjie!

// Multiple interpolations
println("${name} v${version}")  // Cangjie v1

// Expression interpolation
let x = 10
let y = 20
println("${x} + ${y} = ${x + y}")  // 10 + 20 = 30

// Nested string operations
let greeting = "Welcome to ${name}!"
println(greeting)  // Welcome to Cangjie!

// Interpolation with property access
let arr = [1, 2, 3]
println("length = ${arr.size}")  // length = 3

// Empty interpolation parts
println("start${1}end")  // start1end

// String without interpolation
println("no interpolation here")  // no interpolation here

println("PASS: 05_string_interpolation")
