dofile("cangjie-tests/_testing.cj")

// Test: Implicit return with if/match as last expression in function body

// Function with if as last expression
func classify(x: Int64): String {
    if (x > 0) {
        "positive"
    } else if (x < 0) {
        "negative"
    } else {
        "zero"
    }
}

expectEq(classify(5), "positive", "classify(5)")
expectEq(classify(-3), "negative", "classify(-3)")
expectEq(classify(0), "zero", "classify(0)")

// Function with match as last expression
func dayName(d: Int64): String {
    match (d) {
        case 1 => "Monday"
        case 2 => "Tuesday"
        case 3 => "Wednesday"
        case _ => "Other"
    }
}

expectEq(dayName(1), "Monday", "dayName(1)")
expectEq(dayName(3), "Wednesday", "dayName(3)")
expectEq(dayName(99), "Other", "dayName(99)")

// Function with if + explicit return in middle, match at end
func describe(x: Int64): String {
    if (x < 0) {
        return "negative"
    }
    match (x) {
        case 0 => "zero"
        case 1 => "one"
        case _ => "many"
    }
}

expectEq(describe(-1), "negative", "describe(-1)")
expectEq(describe(0), "zero", "describe(0)")
expectEq(describe(1), "one", "describe(1)")
expectEq(describe(42), "many", "describe(42)")

// Enum match with implicit return
enum Color {
    | Red
    | Green
    | Blue(Int64)
}

func colorName(c): String {
    match (c) {
        case Red => "red"
        case Green => "green"
        case Blue(v) => "blue(" + tostring(v) + ")"
        case _ => "unknown"
    }
}

expectEq(colorName(Red), "red", "colorName(Red)")
expectEq(colorName(Blue(42)), "blue(42)", "colorName(Blue(42))")

// Recursive function with if as last expression
func factorial(n: Int64): Int64 {
    if (n <= 1) {
        1
    } else {
        n * factorial(n - 1)
    }
}

expectEq(factorial(5), 120, "factorial(5)")

// Normal if statement in middle of function should still work
func absVal(x: Int64): Int64 {
    if (x < 0) {
        return -x
    }
    x
}

expectEq(absVal(-7), 7, "absVal(-7)")
expectEq(absVal(3), 3, "absVal(3)")

if (!__test_failed) {
    println("PASS: 29_implicit_return_control_flow")
}
