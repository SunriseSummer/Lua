// Test: String interpolation
// Validates basic interpolation, multiple interpolations, expression interpolation,
// variable assignment with interpolation, property access, and literal strings.

let name = "Cangjie"
let version = 1

// -- Section: basic interpolation --
let s1 = "Hello, ${name}!"
if (s1 != "Hello, Cangjie!") { println("FAIL: basic interp expected 'Hello, Cangjie!', got '${s1}'"); return () }

// -- Section: multiple interpolations --
let s2 = "${name} v${version}"
if (s2 != "Cangjie v1") { println("FAIL: multi interp expected 'Cangjie v1', got '${s2}'"); return () }

// -- Section: expression interpolation --
let x = 10
let y = 20
let s3 = "${x} + ${y} = ${x + y}"
if (s3 != "10 + 20 = 30") { println("FAIL: expr interp expected '10 + 20 = 30', got '${s3}'"); return () }

// -- Section: variable with interpolation --
let greeting = "Welcome to ${name}!"
if (greeting != "Welcome to Cangjie!") { println("FAIL: greeting expected 'Welcome to Cangjie!', got '${greeting}'"); return () }

// -- Section: interpolation with property access --
let arr = [1, 2, 3]
let s4 = "length = ${arr.size}"
if (s4 != "length = 3") { println("FAIL: property interp expected 'length = 3', got '${s4}'"); return () }

// -- Section: numeric interpolation --
let s5 = "start${1}end"
if (s5 != "start1end") { println("FAIL: numeric interp expected 'start1end', got '${s5}'"); return () }

// -- Section: no interpolation --
let s6 = "no interpolation here"
if (s6 != "no interpolation here") { println("FAIL: plain string mismatch"); return () }

println("PASS: 05_string_interpolation")
