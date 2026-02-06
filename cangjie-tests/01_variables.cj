// Test: Variable declarations (let and var)
// let = immutable, var = mutable

// let declarations with type annotations
let a: Int64 = 10
let b: Float64 = 3.14
let c: String = "hello"
let d: Bool = true
let e: Bool = false

println(a)      // 10
println(b)      // 3.14
println(c)      // hello
println(d)      // true
println(e)      // false

// Rune (character) type
let ch: Rune = "A"
println(ch)     // A

// var declarations (mutable)
var x: Int64 = 1
println(x)      // 1
x = 2
println(x)      // 2
x = x + 10
println(x)      // 12

// Array type
let arr: Array<Int64> = [1, 2, 3, 4, 5]
println(arr[1])     // 1
println(arr.size)   // 5

// let without type annotation (type inference)
let pi = 3.14159
println(pi)

// nil value
let z = nil
println(z)      // nil

// Multiple declarations
let m, n = 100, 200
println(m)      // 100
println(n)      // 200

println("PASS: 01_variables")
