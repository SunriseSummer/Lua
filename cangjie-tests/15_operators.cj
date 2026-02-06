// Test: Operators (logical, power, bitwise)

// Logical AND (&&)
println("true && true = ${true && true}")
println("true && false = ${true && false}")
println("false && true = ${false && true}")
println("false && false = ${false && false}")

// Logical OR (||)
println("true || true = ${true || true}")
println("true || false = ${true || false}")
println("false || true = ${false || true}")
println("false || false = ${false || false}")

// Logical NOT (!)
println("!true = ${!true}")
println("!false = ${!false}")

// Short-circuit evaluation
var x = 0
func sideEffect(): Bool {
  x = x + 1
  return true
}
let r1 = false && sideEffect()
println("short-circuit &&: x = ${x}")  // x should be 0 (sideEffect not called)
let r2 = true || sideEffect()
println("short-circuit ||: x = ${x}")  // x should be 0 (sideEffect not called)

// Power operator (**)
println("2 ** 0 = ${2 ** 0}")
println("2 ** 10 = ${2 ** 10}")
println("3 ** 3 = ${3 ** 3}")

// Bitwise XOR (^)
println("5 ^ 3 = ${5 ^ 3}")      // 101 XOR 011 = 110 = 6
println("0xFF ^ 0x0F = ${0xFF ^ 0x0F}")  // 240

// Bitwise AND (&)
println("5 & 3 = ${5 & 3}")      // 101 AND 011 = 001 = 1
println("0xFF & 0x0F = ${0xFF & 0x0F}")  // 15

// Bitwise OR (|)
println("5 | 3 = ${5 | 3}")      // 101 OR 011 = 111 = 7
println("0xF0 | 0x0F = ${0xF0 | 0x0F}")  // 255

// Bitwise NOT (~)
println("~0 = ${~0}")            // -1

// Bit shift operators
println("1 << 4 = ${1 << 4}")    // 16
println("16 >> 2 = ${16 >> 2}")  // 4

// Combined expressions
let a = 5
let b = 3
println("a > 0 && b > 0 = ${a > 0 && b > 0}")
println("a > 10 || b > 0 = ${a > 10 || b > 0}")
println("!(a == b) = ${!(a == b)}")

println("PASS: 15_operators")
