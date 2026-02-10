dofile("cangjie-tests/_testing.cj")

// Test: Tuple advanced patterns

// --- Section: Mixed type tuple ---
let t2 = (1, "hello", true, 3.14)
expectEq(t2[0], 1, "mixed tuple int")
expectEq(t2[1], "hello", "mixed tuple string")
expectEq(t2[2], true, "mixed tuple bool")
expectEq(t2[3], 3.14, "mixed tuple float")

// --- Section: Nested tuple via variables ---
let inner1 = (1, 2)
let inner2 = (3, 4)
let outer = (inner1, inner2)
expectEq(outer[0][0], 1, "nested tuple [0][0]")
expectEq(outer[0][1], 2, "nested tuple [0][1]")
expectEq(outer[1][0], 3, "nested tuple [1][0]")
expectEq(outer[1][1], 4, "nested tuple [1][1]")

// --- Section: Tuple returned from function ---
func divmod(a: Int64, b: Int64) {
    return (Float64(a) / b, a % b)
}
let dm = divmod(15, 5)
expectEq(dm[0], 3.0, "divmod quotient")
expectEq(dm[1], 0, "divmod remainder")

let dm2 = divmod(17, 5)
expectEq(dm2[1], 2, "divmod remainder 17%5")

// --- Section: Tuple with zero values ---
let zeros = (0, 0.0, "", false)
expectEq(zeros[0], 0, "tuple zero int")
expectEq(zeros[1], 0.0, "tuple zero float")
expectEq(zeros[2], "", "tuple empty string")
expectEq(zeros[3], false, "tuple false bool")

// --- Section: Large tuple ---
let big = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
expectEq(big[0], 1, "big tuple first")
expectEq(big[9], 10, "big tuple last")
var bigSum = 0
for (i in 0..10) {
    bigSum = bigSum + big[i]
}
expectEq(bigSum, 55, "big tuple sum")

// --- Section: Tuple pattern matching ---
func classifyPair(p) {
    match (p) {
        case (x, y) =>
            if (x == 0 && y == 0) { return "origin" }
            if (y == 0) { return "x-axis" }
            if (x == 0) { return "y-axis" }
            return "general"
    }
}
expectEq(classifyPair((0, 0)), "origin", "tuple match origin")
expectEq(classifyPair((5, 0)), "x-axis", "tuple match x-axis")
expectEq(classifyPair((0, 3)), "y-axis", "tuple match y-axis")
expectEq(classifyPair((2, 3)), "general", "tuple match general")

// --- Section: Tuple in string interpolation ---
let coord = (10, 20)
expectEq("x=${coord[0]}, y=${coord[1]}", "x=10, y=20", "tuple in interpolation")

// --- Section: Tuple as function parameter ---
func sumTuple(t) {
    return t[0] + t[1] + t[2]
}
expectEq(sumTuple((10, 20, 30)), 60, "tuple as parameter")

if (!__test_failed) {
    println("PASS: 60_tuple_advanced")
}
