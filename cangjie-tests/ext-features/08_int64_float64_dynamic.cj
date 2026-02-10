dofile("cangjie-tests/_testing.cj")

// Test: Dynamic type behavior with Int64/Float64

// --- Section: Dynamic dispatch of arithmetic ---
// When types aren't known at compile time, runtime handles correctly
func doArith(a, b, op: String) {
    if (op == "add") { return a + b }
    if (op == "sub") { return a - b }
    if (op == "mul") { return a * b }
    if (op == "div") { return a / b }
    if (op == "mod") { return a % b }
    if (op == "pow") { return a ** b }
    return nil
}

// int/int operations produce int
expectEq(doArith(10, 3, "add"), 13, "dynamic int add")
expectEq(doArith(10, 3, "sub"), 7, "dynamic int sub")
expectEq(doArith(10, 3, "mul"), 30, "dynamic int mul")
expectEq(doArith(10, 3, "div"), 3, "dynamic int div")
expectEq(doArith(10, 3, "mod"), 1, "dynamic int mod")
expectEq(doArith(2, 10, "pow"), 1024, "dynamic int pow")

// float/float operations produce float
expectEq(doArith(10.0, 3.0, "add"), 13.0, "dynamic float add")
expectEq(doArith(10.0, 3.0, "div"), 3.3333333333333335, "dynamic float div")

// mixed operations produce float
expectEq(doArith(10, 3.0, "add"), 13.0, "dynamic mixed add")
expectEq(doArith(10, 3.0, "div"), 3.3333333333333335, "dynamic mixed div")
expectEq(doArith(10.0, 3, "mul"), 30.0, "dynamic mixed mul")

// --- Section: Type checking at runtime ---
func isInt(v) {
    // tostring of int has no decimal point, float always has one
    let s = tostring(v)
    return string.find(s, ".", 1, true) == nil
}

expectTrue(isInt(42), "42 is int")
expectFalse(isInt(42.0), "42.0 is not int")
expectTrue(isInt(10 / 3), "10/3 result is int")
expectFalse(isInt(10 / 3.0), "10/3.0 result is float")
expectTrue(isInt(2 ** 10), "2**10 result is int")
expectFalse(isInt(2.0 ** 10), "2.0**10 result is float")

// --- Section: Dynamic collection with mixed types ---
let mixed = [1, 2.0, 3, 4.0, 5]
var intCount = 0
var floatCount = 0
for (v in mixed) {
    if (isInt(v)) { intCount = intCount + 1 }
    else { floatCount = floatCount + 1 }
}
expectEq(intCount, 3, "3 ints in mixed array")
expectEq(floatCount, 2, "2 floats in mixed array")

// --- Section: Accumulator pattern ---
var intAcc = 0
var floatAcc = 0.0
for (i in 1..=10) {
    intAcc = intAcc + i
    floatAcc = floatAcc + Float64(i) * 0.1
}
expectEq(intAcc, 55, "int accumulator 1..10")

if (!__test_failed) {
    println("PASS: 08_int64_float64_dynamic")
}
