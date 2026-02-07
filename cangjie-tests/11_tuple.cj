dofile("cangjie-tests/_testing.cj")

// Test: Tuple type — indexing, mixed types, pairs, function return, nesting, __n field

// --- Basic tuple creation and indexing ---
let t1 = (1, 2, 3)
expectEq(t1[0], 1, "t1[0]")
expectEq(t1[1], 2, "t1[1]")
expectEq(t1[2], 3, "t1[2]")

// --- Mixed type tuple ---
let t2 = (42, "hello", true, 3.14)
expectEq(t2[0], 42, "t2[0]")
expectEq(t2[1], "hello", "t2[1]")
expectEq(t2[2], true, "t2[2]")
expectEq(t2[3], 3.14, "t2[3]")

// --- Two-element tuple (pair) ---
let pair = ("name", "Alice")
expectEq(pair[0], "name", "pair[0]")
expectEq(pair[1], "Alice", "pair[1]")

// --- Tuple as function return value ---
func minmax(a: Int64, b: Int64) {
  if (a < b) {
    return (a, b)
  }
  return (b, a)
}

let result = minmax(17, 5)
expectEq(result[0], 5, "minmax min")
expectEq(result[1], 17, "minmax max")

// --- Tuple with nested values ---
let t_inner1 = (1, 2)
let t_inner2 = (3, 4)
let nested = (t_inner1, t_inner2)
let inner1 = nested[0]
let inner2 = nested[1]
expectEq(inner1[0], 1, "inner1[0]")
expectEq(inner1[1], 2, "inner1[1]")
expectEq(inner2[0], 3, "inner2[0]")
expectEq(inner2[1], 4, "inner2[1]")

// --- Tuple size via __n field ---
let t3 = (10, 20, 30)
expectEq(t3.__n, 3, "t3.__n")

if (!__test_failed) {
    println("PASS: 11_tuple")
}
