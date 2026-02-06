// Test: Variable declarations (let and var)
// let = immutable, var = mutable

// let declarations (immutable)
let a = 10
let b = 3.14
let c = "hello"
let d = true
let e = false

println(a)      // 10
println(b)      // 3.14
println(c)      // hello
println(d)      // true
println(e)      // false

// var declarations (mutable)
var x = 1
println(x)      // 1
x = 2
println(x)      // 2
x = x + 10
println(x)      // 12

// Multiple declarations
let m, n = 100, 200
println(m)      // 100
println(n)      // 200

// nil value
let z = nil
println(z)      // nil

println("PASS: 01_variables")
