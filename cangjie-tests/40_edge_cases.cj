dofile("cangjie-tests/_testing.cj")

// Test: Edge cases for variables, types, and operators

// --- Negative numbers ---
let neg: Int64 = -42
expectEq(neg, -42, "negative int")
let neg2 = -3.14
expectEq(neg2, -3.14, "negative float")

// --- Zero values ---
let zero_int: Int64 = 0
let zero_flt: Float64 = 0.0
expectEq(zero_int, 0, "zero int")
expectEq(zero_flt, 0.0, "zero float")

// --- Large numbers ---
let big = 1000000000
expectEq(big * 2, 2000000000, "large multiply")

// --- Integer division ---
expectEq(7 / 2, 3.5, "7/2 float div")
expectEq(10 / 5, 2.0, "10/5 exact div")
expectEq(-7 / 2, -3.5, "neg div")

// --- Modulo with negative ---
expectEq(7 % 3, 1, "7%3")
expectEq(-7 % 3, -1, "-7%3")

// --- Boolean edge cases ---
let t: Bool = true
let f: Bool = false
expectEq(!(!t), true, "double negation true")
expectEq(!(!f), false, "double negation false")

// --- Chained comparisons via logical operators ---
let x = 5
expectTrue(1 < x && x < 10, "chained range check")
expectFalse(10 < x && x < 20, "chained range fail")

// --- String edge cases ---
let empty_str: String = ""
expectEq(empty_str, "", "empty string")
let special = "line1\nline2"
expectTrue(special != "line1line2", "string with newline")

// --- Type conversion edge cases ---
expectEq(tostring(true), "true", "tostring(true)")
expectEq(tostring(false), "false", "tostring(false)")
expectEq(tostring(nil), "nil", "tostring(nil)")
expectEq(tostring(0), "0", "tostring(0)")
expectEq(tostring(-1), "-1", "tostring(-1)")

// --- Power operator edge cases ---
expectEq(0 ** 0, 1, "0**0")
expectEq(1 ** 100, 1, "1**100")
expectEq((-1) ** 2, 1, "(-1)**2")

// --- Bitwise edge cases ---
expectEq(0 & 0, 0, "0&0")
expectEq(0 | 0, 0, "0|0")
expectEq(0 ^ 0, 0, "0^0")

// --- Multiple assignment from function return ---
func multiReturn(): (Int64, String) {
    return (42, "hello")
}
let mr = multiReturn()
expectEq(mr[0], 42, "multi return first")
expectEq(mr[1], "hello", "multi return second")

// --- Variable shadowing in blocks ---
let shadow = 10
if (true) {
    let shadow = 20
    expectEq(shadow, 20, "inner shadow")
}
expectEq(shadow, 10, "outer shadow preserved")

// --- Operator precedence ---
expectEq(2 + 3 * 4, 14, "precedence add/mul")
expectEq((2 + 3) * 4, 20, "parens override precedence")
expectEq(10 - 2 - 3, 5, "left assoc subtraction")

if (!__test_failed) {
    println("PASS: 40_edge_cases")
}
