dofile("cangjie-tests/_testing.cj")

// Test: String interpolation

let name = "Cangjie"
let version = 1

// -- Section: basic interpolation --
let s1 = "Hello, ${name}!"
expectEq(s1, "Hello, Cangjie!", "basic interpolation")

// -- Section: multiple interpolations --
let s2 = "${name} v${version}"
expectEq(s2, "Cangjie v1", "multi interpolation")

// -- Section: expression interpolation --
let x = 10
let y = 20
let s3 = "${x} + ${y} = ${x + y}"
expectEq(s3, "10 + 20 = 30", "expr interpolation")

// -- Section: variable with interpolation --
let greeting = "Welcome to ${name}!"
expectEq(greeting, "Welcome to Cangjie!", "greeting interpolation")

// -- Section: interpolation with property access --
let arr = [1, 2, 3]
let s4 = "length = ${arr.size}"
expectEq(s4, "length = 3", "property interpolation")

// -- Section: numeric interpolation --
let s5 = "start${1}end"
expectEq(s5, "start1end", "numeric interpolation")

// -- Section: no interpolation --
let s6 = "no interpolation here"
expectEq(s6, "no interpolation here", "plain string")

if (!__test_failed) {
    println("PASS: 05_string_interpolation")
}
