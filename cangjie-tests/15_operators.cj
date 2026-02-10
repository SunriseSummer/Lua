dofile("cangjie-tests/_testing.cj")

// Test: Operators — logical (&&, ||, !), short-circuit, power (**), bitwise (^, &, |, ~), shifts (<<, >>)

// --- Logical AND (&&) ---
expectTrue(true && true, "true && true")
expectFalse(true && false, "true && false")
expectFalse(false && true, "false && true")
expectFalse(false && false, "false && false")

// --- Logical OR (||) ---
expectTrue(true || true, "true || true")
expectTrue(true || false, "true || false")
expectTrue(false || true, "false || true")
expectFalse(false || false, "false || false")

// --- Logical NOT (!) ---
expectFalse(!true, "!true")
expectTrue(!false, "!false")

// --- Short-circuit evaluation ---
var x = 0
func sideEffect(): Bool {
  x = x + 1
  return true
}
let r1 = false && sideEffect()
expectEq(x, 0, "short-circuit && x")
let r2 = true || sideEffect()
expectEq(x, 0, "short-circuit || x")

// --- Power operator (**) ---
expectEq(2 ** 0, 1, "2**0")
expectEq(2 ** 10, 1024, "2**10")
expectEq(3 ** 3, 27, "3**3")

// --- Bitwise XOR (^) ---
expectEq(5 ^ 3, 6, "5^3")
expectEq(0xFF ^ 0x0F, 240, "0xFF^0x0F")

// --- Bitwise AND (&) ---
expectEq(5 & 3, 1, "5&3")
expectEq(0xFF & 0x0F, 15, "0xFF&0x0F")

// --- Bitwise OR (|) ---
expectEq(5 | 3, 7, "5|3")
expectEq(0xF0 | 0x0F, 255, "0xF0|0x0F")

// --- Bitwise NOT (~) ---
expectEq(~0, -1, "~0")

// --- Bit shift operators ---
expectEq(1 << 4, 16, "1<<4")
expectEq(16 >> 2, 4, "16>>2")

// --- Combined expressions ---
let a = 5
let b = 3
expectTrue(a > 0 && b > 0, "a>0 && b>0")
expectTrue(a > 10 || b > 0, "a>10 || b>0")
expectTrue(!(a == b), "!(a==b)")

if (!__test_failed) {
    println("PASS: 15_operators")
}
