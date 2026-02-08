dofile("cangjie-tests/_testing.cj")

// Test: Lambda and closure edge cases

// --- Lambda with no params (arrow syntax) ---
let always42 = () => 42
expectEq(always42(), 42, "no-param arrow lambda")

// --- Lambda with single expression body ---
let double = { x => x * 2 }
expectEq(double(21), 42, "single expr lambda")

// --- Closure captures mutable variable ---
var counter = 0
let inc = { => counter = counter + 1; return counter }
expectEq(inc(), 1, "closure capture 1")
expectEq(inc(), 2, "closure capture 2")
expectEq(counter, 2, "outer var updated")

// --- Multiple closures sharing same variable ---
var shared = 0
let add1 = { => shared = shared + 1 }
let add10 = { => shared = shared + 10 }
let getVal = { => shared }
add1()
add10()
expectEq(getVal(), 11, "shared closure var")

// --- Higher-order: function returning function ---
func multiplier(factor: Int64) {
    return { x => x * factor }
}
let times3 = multiplier(3)
let times5 = multiplier(5)
expectEq(times3(7), 21, "multiplier(3)(7)")
expectEq(times5(7), 35, "multiplier(5)(7)")

// --- Lambda as callback ---
func applyTwice(f, x) {
    return f(f(x))
}
expectEq(applyTwice({ x => x + 1 }, 0), 2, "applyTwice inc")
expectEq(applyTwice({ x => x * 2 }, 3), 12, "applyTwice double")

// --- Nested lambdas ---
let compose = { f, g => { x => f(g(x)) } }
let add1_fn = { x => x + 1 }
let double_fn = { x => x * 2 }
let add1ThenDouble = compose(double_fn, add1_fn)
expectEq(add1ThenDouble(3), 8, "compose (3+1)*2")

// --- Lambda with multi-line body ---
let clamp = { x: Int64, lo: Int64, hi: Int64 =>
    if (x < lo) {
        return lo
    }
    if (x > hi) {
        return hi
    }
    return x
}
expectEq(clamp(-5, 0, 10), 0, "clamp low")
expectEq(clamp(5, 0, 10), 5, "clamp mid")
expectEq(clamp(15, 0, 10), 10, "clamp high")

// --- Immediately invoked lambda (via variable) ---
let iife_fn = { => 42 }
let result = iife_fn()
expectEq(result, 42, "IIFE via var")

// --- Lambda stored in array ---
let ops = [
    { a, b => a + b },
    { a, b => a - b },
    { a, b => a * b }
]
expectEq(ops[0](10, 3), 13, "lambda array add")
expectEq(ops[1](10, 3), 7, "lambda array sub")
expectEq(ops[2](10, 3), 30, "lambda array mul")

// --- Recursive lambda via variable ---
var fib = { n => 0 }
fib = { n =>
    if (n <= 1) { return n }
    return fib(n - 1) + fib(n - 2)
}
expectEq(fib(0), 0, "fib(0)")
expectEq(fib(1), 1, "fib(1)")
expectEq(fib(10), 55, "fib(10)")

if (!__test_failed) {
    println("PASS: 44_lambda_closure_edge_cases")
}
