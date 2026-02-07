// Test: Operators — logical (&&, ||, !), short-circuit, power (**), bitwise (^, &, |, ~), shifts (<<, >>)

// --- Logical AND (&&) ---
if ((true && true) != true) { println("FAIL: true && true expected true"); return () }
if ((true && false) != false) { println("FAIL: true && false expected false"); return () }
if ((false && true) != false) { println("FAIL: false && true expected false"); return () }
if ((false && false) != false) { println("FAIL: false && false expected false"); return () }

// --- Logical OR (||) ---
if ((true || true) != true) { println("FAIL: true || true expected true"); return () }
if ((true || false) != true) { println("FAIL: true || false expected true"); return () }
if ((false || true) != true) { println("FAIL: false || true expected true"); return () }
if ((false || false) != false) { println("FAIL: false || false expected false"); return () }

// --- Logical NOT (!) ---
if ((!true) != false) { println("FAIL: !true expected false"); return () }
if ((!false) != true) { println("FAIL: !false expected true"); return () }

// --- Short-circuit evaluation ---
var x = 0
func sideEffect(): Bool {
  x = x + 1
  return true
}
let r1 = false && sideEffect()
if (x != 0) { println("FAIL: short-circuit && expected x=0, got ${x}"); return () }
let r2 = true || sideEffect()
if (x != 0) { println("FAIL: short-circuit || expected x=0, got ${x}"); return () }

// --- Power operator (**) ---
if ((2 ** 0) != 1) { println("FAIL: 2**0 expected 1, got ${2 ** 0}"); return () }
if ((2 ** 10) != 1024) { println("FAIL: 2**10 expected 1024, got ${2 ** 10}"); return () }
if ((3 ** 3) != 27) { println("FAIL: 3**3 expected 27, got ${3 ** 3}"); return () }

// --- Bitwise XOR (^) ---
if ((5 ^ 3) != 6) { println("FAIL: 5^3 expected 6, got ${5 ^ 3}"); return () }
if ((0xFF ^ 0x0F) != 240) { println("FAIL: 0xFF^0x0F expected 240, got ${0xFF ^ 0x0F}"); return () }

// --- Bitwise AND (&) ---
if ((5 & 3) != 1) { println("FAIL: 5&3 expected 1, got ${5 & 3}"); return () }
if ((0xFF & 0x0F) != 15) { println("FAIL: 0xFF&0x0F expected 15, got ${0xFF & 0x0F}"); return () }

// --- Bitwise OR (|) ---
if ((5 | 3) != 7) { println("FAIL: 5|3 expected 7, got ${5 | 3}"); return () }
if ((0xF0 | 0x0F) != 255) { println("FAIL: 0xF0|0x0F expected 255, got ${0xF0 | 0x0F}"); return () }

// --- Bitwise NOT (~) ---
if ((~0) != -1) { println("FAIL: ~0 expected -1, got ${~0}"); return () }

// --- Bit shift operators ---
if ((1 << 4) != 16) { println("FAIL: 1<<4 expected 16, got ${1 << 4}"); return () }
if ((16 >> 2) != 4) { println("FAIL: 16>>2 expected 4, got ${16 >> 2}"); return () }

// --- Combined expressions ---
let a = 5
let b = 3
if ((a > 0 && b > 0) != true) { println("FAIL: a>0 && b>0 expected true"); return () }
if ((a > 10 || b > 0) != true) { println("FAIL: a>10 || b>0 expected true"); return () }
if ((!(a == b)) != true) { println("FAIL: !(a==b) expected true"); return () }

println("PASS: 15_operators")
