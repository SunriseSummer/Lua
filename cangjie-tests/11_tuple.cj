// Test: Tuple type — indexing, mixed types, pairs, function return, nesting, __n field

// --- Basic tuple creation and indexing ---
let t1 = (1, 2, 3)
if (t1[0] != 1) { println("FAIL: t1[0] expected 1, got ${t1[0]}"); return () }
if (t1[1] != 2) { println("FAIL: t1[1] expected 2, got ${t1[1]}"); return () }
if (t1[2] != 3) { println("FAIL: t1[2] expected 3, got ${t1[2]}"); return () }

// --- Mixed type tuple ---
let t2 = (42, "hello", true, 3.14)
if (t2[0] != 42) { println("FAIL: t2[0] expected 42, got ${t2[0]}"); return () }
if (t2[1] != "hello") { println("FAIL: t2[1] expected hello, got ${t2[1]}"); return () }
if (t2[2] != true) { println("FAIL: t2[2] expected true, got ${t2[2]}"); return () }
if (t2[3] != 3.14) { println("FAIL: t2[3] expected 3.14, got ${t2[3]}"); return () }

// --- Two-element tuple (pair) ---
let pair = ("name", "Alice")
if (pair[0] != "name") { println("FAIL: pair[0] expected name, got ${pair[0]}"); return () }
if (pair[1] != "Alice") { println("FAIL: pair[1] expected Alice, got ${pair[1]}"); return () }

// --- Tuple as function return value ---
func minmax(a: Int64, b: Int64) {
  if (a < b) {
    return (a, b)
  }
  return (b, a)
}

let result = minmax(17, 5)
if (result[0] != 5) { println("FAIL: minmax min expected 5, got ${result[0]}"); return () }
if (result[1] != 17) { println("FAIL: minmax max expected 17, got ${result[1]}"); return () }

// --- Tuple with nested values ---
let t_inner1 = (1, 2)
let t_inner2 = (3, 4)
let nested = (t_inner1, t_inner2)
let inner1 = nested[0]
let inner2 = nested[1]
if (inner1[0] != 1) { println("FAIL: inner1[0] expected 1, got ${inner1[0]}"); return () }
if (inner1[1] != 2) { println("FAIL: inner1[1] expected 2, got ${inner1[1]}"); return () }
if (inner2[0] != 3) { println("FAIL: inner2[0] expected 3, got ${inner2[0]}"); return () }
if (inner2[1] != 4) { println("FAIL: inner2[1] expected 4, got ${inner2[1]}"); return () }

// --- Tuple size via __n field ---
let t3 = (10, 20, 30)
if (t3.__n != 3) { println("FAIL: t3.__n expected 3, got ${t3.__n}"); return () }

println("PASS: 11_tuple")
