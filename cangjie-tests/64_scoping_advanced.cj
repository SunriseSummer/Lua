dofile("cangjie-tests/_testing.cj")

// Test: Variable scoping and shadowing edge cases

// --- Section: Let shadowing in nested blocks ---
let x = 10
if (true) {
    let x = 20
    expectEq(x, 20, "inner shadow x")
}
expectEq(x, 10, "outer x preserved")

// --- Section: Var shadowing in nested blocks ---
var y = 100
if (true) {
    var y = 200
    y = y + 1
    expectEq(y, 201, "inner shadow var y")
}
expectEq(y, 100, "outer var y preserved")

// --- Section: Multiple levels of shadowing ---
let z = 1
if (true) {
    let z = 2
    if (true) {
        let z = 3
        expectEq(z, 3, "level 3 shadow z")
    }
    expectEq(z, 2, "level 2 shadow z")
}
expectEq(z, 1, "level 1 z preserved")

// --- Section: Function scope isolation ---
var outer = 0
func modify() {
    var outer = 42
    outer = outer + 1
    expectEq(outer, 43, "function local outer")
}
modify()
expectEq(outer, 0, "global outer not modified")

// --- Section: For loop variable scoping ---
var beforeLoop = 0
for (i in 0..3) {
    beforeLoop = i
}
expectEq(beforeLoop, 2, "for loop var captures last value")

// --- Section: While loop variable scoping ---
var whileVar = 0
var wi = 0
while (wi < 5) {
    var local = wi
    whileVar = local
    wi = wi + 1
}
expectEq(whileVar, 4, "while loop var last value")

// --- Section: Lambda captures outer scope ---
var captured = 10
let fn = { => captured }
expectEq(fn(), 10, "lambda captures outer scope")
captured = 20
expectEq(fn(), 20, "lambda sees updated outer scope")

// --- Section: Shadowing with same name different types ---
let name = 42
if (true) {
    let name = "hello"
    expectEq(name, "hello", "shadow with different type")
}
expectEq(name, 42, "original type preserved")

// --- Section: Nested function scoping ---
func outerFunc(): Int64 {
    let x = 100
    func innerFunc(): Int64 {
        return x + 1
    }
    return innerFunc()
}
expectEq(outerFunc(), 101, "nested function sees outer var")

if (!__test_failed) {
    println("PASS: 64_scoping_advanced")
}
