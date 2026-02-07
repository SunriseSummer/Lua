// Test: Variable declarations (let and var)
// Validates let (immutable) and var (mutable) bindings, type annotations,
// type inference, Rune type, Array indexing, and mutation of var bindings.

// -- Section: let declarations with type annotations --
let a: Int64 = 10
let b: Float64 = 3.14
let c: String = "hello"
let d: Bool = true
let e: Bool = false

if (a != 10) { println("FAIL: a expected 10, got ${a}"); return () }
if (tostring(b) != "3.14") { println("FAIL: b expected 3.14, got ${b}"); return () }
if (c != "hello") { println("FAIL: c expected hello, got ${c}"); return () }
if (d != true) { println("FAIL: d expected true, got ${d}"); return () }
if (e != false) { println("FAIL: e expected false, got ${e}"); return () }

// -- Section: Rune (character) type --
let ch: Rune = 'A'
if (tostring(ch) != "A") { println("FAIL: ch expected A, got ${ch}"); return () }

// -- Section: var declarations (mutable) --
var x: Int64 = 1
if (x != 1) { println("FAIL: x expected 1, got ${x}"); return () }
x = 2
if (x != 2) { println("FAIL: x expected 2 after assignment, got ${x}"); return () }
x = x + 10
if (x != 12) { println("FAIL: x expected 12 after x+10, got ${x}"); return () }

// -- Section: Array type (0-based indexing) --
let arr: Array<Int64> = [1, 2, 3, 4, 5]
if (arr[0] != 1) { println("FAIL: arr[0] expected 1, got ${arr[0]}"); return () }
if (arr[1] != 2) { println("FAIL: arr[1] expected 2, got ${arr[1]}"); return () }
if (arr.size != 5) { println("FAIL: arr.size expected 5, got ${arr.size}"); return () }

// -- Section: type inference --
let pi = 3.14159
if (tostring(pi) != "3.14159") { println("FAIL: pi expected 3.14159, got ${pi}"); return () }

println("PASS: 01_variables")
