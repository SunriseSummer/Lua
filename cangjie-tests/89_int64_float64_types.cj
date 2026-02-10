dofile("cangjie-tests/_testing.cj")

// Test: Int64 and Float64 strict type distinction

// --- Section: Integer literal type ---
let i1 = 42
let i2 = -100
let i3 = 0
expectEq(i1, 42, "integer literal 42")
expectEq(i2, -100, "integer literal -100")
expectEq(i3, 0, "integer literal 0")

// --- Section: Float64 literal type (must have dot) ---
let f1 = 3.14
let f2 = 3.
let f3 = 0.0
let f4 = -1.5
let f5 = 1.0
expectEq(f1, 3.14, "float literal 3.14")
expectEq(f2, 3.0, "float literal 3.")
expectEq(f3, 0.0, "float literal 0.0")
expectEq(f4, -1.5, "float literal -1.5")
expectEq(f5, 1.0, "float literal 1.0")

// --- Section: Integer arithmetic produces integer ---
expectEq(10 + 3, 13, "int + int = int")
expectEq(10 - 3, 7, "int - int = int")
expectEq(10 * 3, 30, "int * int = int")
expectEq(10 / 3, 3, "int / int = int (truncated)")
expectEq(10 % 3, 1, "int % int = int")
expectEq(2 ** 10, 1024, "int ** int = int")

// --- Section: Float64 arithmetic produces Float64 ---
expectEq(10.0 + 3.0, 13.0, "float + float = float")
expectEq(10.0 - 3.0, 7.0, "float - float = float")
expectEq(10.0 * 3.0, 30.0, "float * float = float")
expectEq(10.0 / 3.0, 3.3333333333333335, "float / float = float")
expectEq(10.0 % 3.0, 1.0, "float % float = float")
expectEq(2.0 ** 3.0, 8.0, "float ** float = float")

// --- Section: Mixed arithmetic auto-promotes to float ---
expectEq(10 + 3.0, 13.0, "int + float = float")
expectEq(10.0 + 3, 13.0, "float + int = float")
expectEq(10 - 3.0, 7.0, "int - float = float")
expectEq(10.0 - 3, 7.0, "float - int = float")
expectEq(10 * 3.0, 30.0, "int * float = float")
expectEq(10.0 * 3, 30.0, "float * int = float")
expectEq(10 / 3.0, 3.3333333333333335, "int / float = float")
expectEq(10.0 / 3, 3.3333333333333335, "float / int = float")
expectEq(2.0 ** 3, 8.0, "float ** int = float")
expectEq(2 ** 3.0, 8.0, "int ** float = float")

// --- Section: Explicit type conversion ---
expectEq(Int64(3.14), 3, "Int64(float) truncates")
expectEq(Int64(3.99), 3, "Int64(3.99) truncates")
expectEq(Int64(-2.7), -2, "Int64(-2.7) truncates toward zero")
expectEq(Int64(0.0), 0, "Int64(0.0) = 0")
expectEq(Float64(42), 42.0, "Float64(int) promotes")
expectEq(Float64(0), 0.0, "Float64(0) = 0.0")
expectEq(Float64(-10), -10.0, "Float64(-10) promotes")

// --- Section: Type conversion from strings ---
expectEq(Int64("42"), 42, "Int64 from string")
expectEq(Int64("-100"), -100, "Int64 from negative string")
expectEq(Int64("0"), 0, "Int64 from zero string")
expectEq(Float64("3.14"), 3.14, "Float64 from string")
expectEq(Float64("-1.5"), -1.5, "Float64 from negative string")
expectEq(Float64("0.0"), 0.0, "Float64 from zero string")

// --- Section: Integer division truncation semantics ---
expectEq(7 / 2, 3, "7/2 = 3 (truncated)")
expectEq(-7 / 2, -3, "-7/2 = -3 (toward zero)")
expectEq(7 / -2, -3, "7/-2 = -3 (toward zero)")
expectEq(-7 / -2, 3, "-7/-2 = 3 (toward zero)")
expectEq(1 / 3, 0, "1/3 = 0 (truncated)")
expectEq(-1 / 3, 0, "-1/3 = 0 (toward zero)")
expectEq(100 / 10, 10, "100/10 = 10 (exact)")
expectEq(99 / 10, 9, "99/10 = 9 (truncated)")

// --- Section: Integer power ---
expectEq(2 ** 0, 1, "2^0 = 1")
expectEq(2 ** 1, 2, "2^1 = 2")
expectEq(2 ** 10, 1024, "2^10 = 1024")
expectEq(3 ** 3, 27, "3^3 = 27")
expectEq((-2) ** 3, -8, "(-2)^3 = -8")
expectEq((-2) ** 4, 16, "(-2)^4 = 16")
expectEq(0 ** 0, 1, "0^0 = 1")
expectEq(0 ** 5, 0, "0^5 = 0")
expectEq(1 ** 1000, 1, "1^1000 = 1")
expectEq((-1) ** 0, 1, "(-1)^0 = 1")
expectEq((-1) ** 1, -1, "(-1)^1 = -1")
expectEq((-1) ** 2, 1, "(-1)^2 = 1")
expectEq((-1) ** 3, -1, "(-1)^3 = -1")
expectEq(10 ** 3, 1000, "10^3 = 1000")

// --- Section: Compound assignment preserves type ---
var ca = 24
ca /= 4
expectEq(ca, 6, "int /= int = int")

var cb = 24.0
cb /= 4.0
expectEq(cb, 6.0, "float /= float = float")

var cc = 2
cc = cc ** 10
expectEq(cc, 1024, "int ** int = int (reassign)")

// --- Section: tostring preserves type distinction ---
expectEq(tostring(42), "42", "tostring(int) no decimal")
expectEq(tostring(42.0), "42.0", "tostring(float) has decimal")
expectEq(tostring(0), "0", "tostring(0) int")
expectEq(tostring(0.0), "0.0", "tostring(0.0) float")
expectEq(tostring(3.14), "3.14", "tostring(3.14)")
expectEq(tostring(-1), "-1", "tostring(-1)")
expectEq(tostring(-1.0), "-1.0", "tostring(-1.0)")

// --- Section: Comparison between int and float ---
expectTrue(42 == 42.0, "int == float with same value")
expectTrue(42.0 == 42, "float == int with same value")
expectFalse(42 == 42.5, "int != float different value")
expectTrue(1 < 1.5, "int < float")
expectTrue(1.5 > 1, "float > int")
expectTrue(2 >= 2.0, "int >= float")
expectTrue(2.0 <= 2, "float <= int")

if (!__test_failed) {
    println("PASS: 89_int64_float64_types")
}
