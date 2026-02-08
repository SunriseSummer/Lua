// Test: Comprehensive edge cases for existing features
// Focus: stress-testing boundary conditions across various language features
dofile("cangjie-tests/_testing.cj")

// === Closures and variable capture ===

// Closure captures outer mutable variable
var mutableVal = 10
let getClosure = { => mutableVal }
expectEq(getClosure(), 10, "closure captures initial mutable value")
mutableVal = 20
expectEq(getClosure(), 20, "closure sees updated mutable value")

// === Nested function types ===

// Function returning function returning value
func makeCounter(start: Int64): () -> Int64 {
  var count = start
  return { =>
    count = count + 1
    return count
  }
}
let counter = makeCounter(0)
expectEq(counter(), 1, "closure counter first call")
expectEq(counter(), 2, "closure counter second call")
expectEq(counter(), 3, "closure counter third call")

// === Complex expressions with operators ===

// Chained comparisons in if
let x = 5
var result = ""
if (x > 0 && x < 10) {
  result = "in range"
}
expectEq(result, "in range", "chained comparison with &&")

// Nested ternary-like if expression
let y = 15
let category = if (y < 10) { "small" } else if (y < 20) { "medium" } else { "large" }
expectEq(category, "medium", "nested if expression")

// === String edge cases ===

// Empty string interpolation parts
let empty = ""
let interp = "a${empty}b"
expectEq(interp, "ab", "empty string interpolation")

// Nested interpolation
let inner = "world"
let outer = "hello ${inner}!"
expectEq(outer, "hello world!", "basic string interpolation")

// Interpolation with expression
let n = 6
let expr_interp = "value: ${n * 7}"
expectEq(expr_interp, "value: 42", "expression in interpolation")

// === Tuple edge cases ===

// Single-value tuple vs parenthesized expression
let paren = (42)
expectEq(paren, 42, "parenthesized expression not tuple")

// Tuple with two elements
let pair = (1, 2)
expectEq(pair[0], 1, "tuple first element")
expectEq(pair[1], 2, "tuple second element")

// === Array edge cases ===

// Empty array
let emptyArr: Array<Int64> = []
expectEq(emptyArr.size, 0, "empty array size")

// Single element array
let single = [42]
expectEq(single[0], 42, "single element array")
expectEq(single.size, 1, "single element array size")

// === Function overloading edge cases ===

func greet(): String { return "hello" }
func greet(name: String): String { return "hello ${name}" }
func greet(name: String, greeting: String): String { return "${greeting} ${name}" }

expectEq(greet(), "hello", "overload 0 args")
expectEq(greet("world"), "hello world", "overload 1 arg")
expectEq(greet("world", "hi"), "hi world", "overload 2 args")

// === While loop with complex condition ===

var count = 0
var total = 0
while (count < 10 && total < 30) {
  total = total + count
  count = count + 1
}
expectEq(total, 36, "while with complex condition")
expectEq(count, 9, "while counter after complex condition")

// === Break and continue ===

var breakSum = 0
for (i in 0..10) {
  if (i == 5) { break }
  breakSum = breakSum + i
}
expectEq(breakSum, 10, "break in for loop (0+1+2+3+4)")

var continueSum = 0
for (i in 0..10) {
  if (i % 2 == 0) { continue }
  continueSum = continueSum + i
}
expectEq(continueSum, 25, "continue skipping even numbers (1+3+5+7+9)")

// === Recursive lambda ===

var fib = { n: Int64 => 0 }
fib = { n: Int64 =>
  if (n <= 1) { return n }
  return fib(n - 1) + fib(n - 2)
}
expectEq(fib(0), 0, "recursive lambda fib(0)")
expectEq(fib(1), 1, "recursive lambda fib(1)")
expectEq(fib(10), 55, "recursive lambda fib(10)")

// === Option type edge cases ===

let some: ?Int64 = 42
let none: ?Int64 = nil

expectEq(some ?? 0, 42, "coalesce with some value")
expectEq(none ?? 99, 99, "coalesce with none value")

// Chained coalesce
let a: ?Int64 = nil
let b: ?Int64 = nil
let c: ?Int64 = 7
expectEq(a ?? b ?? c ?? 0, 7, "chained coalesce")

// === Compound assignment ===

var ca = 10
ca += 5
expectEq(ca, 15, "compound += ")
ca -= 3
expectEq(ca, 12, "compound -=")
ca *= 2
expectEq(ca, 24, "compound *=")

if (!__test_failed) {
  println("PASS: all comprehensive edge case tests passed")
}
