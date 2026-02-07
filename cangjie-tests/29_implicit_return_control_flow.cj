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

if (classify(5) != "positive") {
    println("FAIL: classify(5) expected 'positive', got '" + classify(5) + "'")
    return ()
}
if (classify(-3) != "negative") {
    println("FAIL: classify(-3) expected 'negative', got '" + classify(-3) + "'")
    return ()
}
if (classify(0) != "zero") {
    println("FAIL: classify(0) expected 'zero', got '" + classify(0) + "'")
    return ()
}

// Function with match as last expression
func dayName(d: Int64): String {
    match (d) {
        case 1 => "Monday"
        case 2 => "Tuesday"
        case 3 => "Wednesday"
        case _ => "Other"
    }
}

if (dayName(1) != "Monday") {
    println("FAIL: dayName(1) expected 'Monday', got '" + dayName(1) + "'")
    return ()
}
if (dayName(3) != "Wednesday") {
    println("FAIL: dayName(3) expected 'Wednesday', got '" + dayName(3) + "'")
    return ()
}
if (dayName(99) != "Other") {
    println("FAIL: dayName(99) expected 'Other', got '" + dayName(99) + "'")
    return ()
}

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

if (describe(-1) != "negative") {
    println("FAIL: describe(-1) expected 'negative', got '" + describe(-1) + "'")
    return ()
}
if (describe(0) != "zero") {
    println("FAIL: describe(0) expected 'zero', got '" + describe(0) + "'")
    return ()
}
if (describe(1) != "one") {
    println("FAIL: describe(1) expected 'one', got '" + describe(1) + "'")
    return ()
}
if (describe(42) != "many") {
    println("FAIL: describe(42) expected 'many', got '" + describe(42) + "'")
    return ()
}

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

if (colorName(Red) != "red") {
    println("FAIL: colorName(Red) expected 'red', got '" + colorName(Red) + "'")
    return ()
}
if (colorName(Blue(42)) != "blue(42)") {
    println("FAIL: colorName(Blue(42)) expected 'blue(42)', got '" + colorName(Blue(42)) + "'")
    return ()
}

// Recursive function with if as last expression
func factorial(n: Int64): Int64 {
    if (n <= 1) {
        1
    } else {
        n * factorial(n - 1)
    }
}

if (factorial(5) != 120) {
    println("FAIL: factorial(5) expected 120, got " + tostring(factorial(5)))
    return ()
}

// Normal if statement in middle of function should still work
func absVal(x: Int64): Int64 {
    if (x < 0) {
        return -x
    }
    x
}

if (absVal(-7) != 7) {
    println("FAIL: absVal(-7) expected 7, got " + tostring(absVal(-7)))
    return ()
}
if (absVal(3) != 3) {
    println("FAIL: absVal(3) expected 3, got " + tostring(absVal(3)))
    return ()
}

println("PASS: 29_implicit_return_control_flow")
