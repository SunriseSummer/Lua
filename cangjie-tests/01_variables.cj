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

// Rune (character) type - using single quotes
let ch: Rune = 'A'
println(ch)     // A

// var declarations (mutable)
var x: Int64 = 1
println(x)      // 1
x = 2
println(x)      // 2
x = x + 10
println(x)      // 12

// Array type (0-based indexing)
let arr: Array<Int64> = [1, 2, 3, 4, 5]
println(arr[0])     // 1 (first element, 0-based)
println(arr[1])     // 2 (second element)
println(arr.size)   // 5

// let without type annotation (type inference)
let pi = 3.14159
println(pi)

println("PASS: 01_variables")
