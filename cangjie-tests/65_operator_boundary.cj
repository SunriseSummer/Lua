dofile("cangjie-tests/_testing.cj")

// Test: Operator edge cases and precedence

// --- Section: Arithmetic precedence ---
expectEq(2 + 3 * 4, 14, "2+3*4 = 14 (mul first)")
expectEq((2 + 3) * 4, 20, "(2+3)*4 = 20")
expectEq(10 - 3 - 2, 5, "left-associative subtraction")
expectEq(10 - (3 - 2), 9, "10-(3-2) = 9")

// --- Section: Modulo with various operands ---
expectEq(10 % 3, 1, "10 % 3 = 1")
expectEq(0 % 5, 0, "0 % 5 = 0")
expectEq(7 % 1, 0, "7 % 1 = 0")
expectEq(5 % 5, 0, "5 % 5 = 0")

// --- Section: Power operator ---
expectEq(2 ** 0, 1, "2**0 = 1")
expectEq(2 ** 1, 2, "2**1 = 2")
expectEq(0 ** 0, 1, "0**0 = 1")
expectEq(1 ** 100, 1, "1**100 = 1")

// --- Section: Bitwise operators ---
expectEq(0xFF & 0x0F, 0x0F, "0xFF & 0x0F = 0x0F")
expectEq(0xF0 | 0x0F, 0xFF, "0xF0 | 0x0F = 0xFF")
expectEq(0xFF ^ 0x0F, 0xF0, "0xFF ^ 0x0F = 0xF0")
expectEq(1 << 0, 1, "1 << 0 = 1")
expectEq(1 << 3, 8, "1 << 3 = 8")
expectEq(8 >> 3, 1, "8 >> 3 = 1")
expectEq(0 << 10, 0, "0 << 10 = 0")
expectEq(0 >> 10, 0, "0 >> 10 = 0")

// --- Section: Logical operators ---
expectTrue(true && true, "true && true")
expectFalse(true && false, "true && false")
expectFalse(false && true, "false && true")
expectFalse(false && false, "false && false")
expectTrue(true || true, "true || true")
expectTrue(true || false, "true || false")
expectTrue(false || true, "false || true")
expectFalse(false || false, "false || false")
expectTrue(!false, "!false")
expectFalse(!true, "!true")

// --- Section: Short-circuit evaluation ---
var shortCircuit = 0
func sideEffect(): Bool {
    shortCircuit = shortCircuit + 1
    return true
}
let _sc1 = false && sideEffect()
expectEq(shortCircuit, 0, "short-circuit && skips second")
let _sc2 = true || sideEffect()
expectEq(shortCircuit, 0, "short-circuit || skips second")

// --- Section: Comparison operators boundary ---
expectTrue(0 == 0, "0 == 0")
expectFalse(0 != 0, "0 != 0")
expectTrue(-1 < 0, "-1 < 0")
expectTrue(0 <= 0, "0 <= 0")
expectTrue(0 >= 0, "0 >= 0")
expectFalse(0 > 0, "0 > 0")

// --- Section: Float comparison ---
expectTrue(0.1 + 0.2 > 0.29, "0.1+0.2 > 0.29")
expectTrue(1.0 == 1.0, "1.0 == 1.0")
expectTrue(1.0 != 1.1, "1.0 != 1.1")

// --- Section: Compound assignment ---
var ca = 10
ca += 5
expectEq(ca, 15, "+= 5")
ca -= 3
expectEq(ca, 12, "-= 3")
ca *= 2
expectEq(ca, 24, "*= 2")
ca /= 4
expectEq(ca, 6.0, "/= 4")

// --- Section: Compound assignment with expressions ---
var cb = 1
cb += 2 + 3
expectEq(cb, 6, "+= complex expression")

// --- Section: Negative number operations ---
expectEq(-1 * -1, 1, "neg * neg = pos")
expectEq(-5 + 5, 0, "-5 + 5 = 0")
expectEq(0 - 0, 0, "0 - 0 = 0")

if (!__test_failed) {
    println("PASS: 65_operator_boundary")
}
