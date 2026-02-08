dofile("cangjie-tests/_testing.cj")

// Test: Function and lambda boundary cases

// --- Section: Function with no parameters ---
func getFortyTwo(): Int64 {
    return 42
}
expectEq(getFortyTwo(), 42, "no param function")

// --- Section: Function returning nothing (Unit) ---
var sideEffect = 0
func doWork() {
    sideEffect = sideEffect + 1
}
doWork()
expectEq(sideEffect, 1, "unit function side effect")

// --- Section: Recursive fibonacci ---
func fib(n: Int64): Int64 {
    if (n <= 1) { return n }
    return fib(n - 1) + fib(n - 2)
}
expectEq(fib(0), 0, "fib(0)")
expectEq(fib(1), 1, "fib(1)")
expectEq(fib(2), 1, "fib(2)")
expectEq(fib(10), 55, "fib(10)")

// --- Section: Mutual recursion ---
func isEven(n: Int64): Bool {
    if (n == 0) { return true }
    return isOdd(n - 1)
}
func isOdd(n: Int64): Bool {
    if (n == 0) { return false }
    return isEven(n - 1)
}
expectTrue(isEven(10), "10 is even")
expectFalse(isEven(7), "7 is not even")
expectTrue(isOdd(7), "7 is odd")
expectFalse(isOdd(10), "10 is not odd")

// --- Section: Closure captures mutable variable ---
func makeAccumulator(): (Int64) -> Int64 {
    var total = 0
    return { n: Int64 =>
        total = total + n
        return total
    }
}
let acc = makeAccumulator()
expectEq(acc(5), 5, "accumulator 5")
expectEq(acc(3), 8, "accumulator 5+3")
expectEq(acc(2), 10, "accumulator 5+3+2")

// --- Section: Lambda as IIFE ---
let iife = { => 100 }()
expectEq(iife, 100, "IIFE result")

// --- Section: Lambda with multiple statements ---
let multiStmt = { x: Int64 =>
    var result = x * 2
    result = result + 1
    return result
}
expectEq(multiStmt(5), 11, "multi-statement lambda")

// --- Section: Higher-order function ---
func apply(fn: (Int64) -> Int64, x: Int64): Int64 {
    return fn(x)
}
expectEq(apply({ x => x * x }, 5), 25, "higher-order apply square")
expectEq(apply({ x => x + 10 }, 5), 15, "higher-order apply add10")

// --- Section: Function returning lambda ---
func multiplier(factor: Int64): (Int64) -> Int64 {
    return { x: Int64 => x * factor }
}
let double = multiplier(2)
let triple = multiplier(3)
expectEq(double(5), 10, "multiplier double")
expectEq(triple(5), 15, "multiplier triple")

// --- Section: Lambda in array ---
let lambdas = [
    { => 10 },
    { => 20 },
    { => 30 }
]
expectEq(lambdas[0](), 10, "lambda array 0")
expectEq(lambdas[1](), 20, "lambda array 1")
expectEq(lambdas[2](), 30, "lambda array 2")

// --- Section: Nested lambda ---
let nested = { a: Int64 => { b: Int64 => a + b } }
expectEq(nested(3)(4), 7, "nested lambda 3+4")

// --- Section: Function overload by arity ---
func info(): String { return "no args" }
func info(a: Int64): String { return "one: ${a}" }
func info(a: Int64, b: Int64): String { return "two: ${a}, ${b}" }

expectEq(info(), "no args", "overload 0 args")
expectEq(info(1), "one: 1", "overload 1 arg")
expectEq(info(1, 2), "two: 1, 2", "overload 2 args")

// --- Section: Named parameter with default ---
func power(base: Int64, exponent!: Int64 = 2): Int64 {
    var result = 1
    for (i in 0..exponent) {
        result = result * base
    }
    return result
}
expectEq(power(3), 9, "named param default exponent=2")
expectEq(power(2, exponent: 10), 1024, "named param exponent=10")

// --- Section: Implicit return (last expression) ---
func add(a: Int64, b: Int64): Int64 {
    a + b
}
expectEq(add(3, 4), 7, "implicit return add")

func conditional(x: Int64): String {
    if (x > 0) { "positive" } else { "non-positive" }
}
expectEq(conditional(5), "positive", "implicit return if")
expectEq(conditional(-1), "non-positive", "implicit return else")

if (!__test_failed) {
    println("PASS: 61_func_lambda_boundary")
}
