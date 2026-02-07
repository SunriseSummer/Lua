dofile("cangjie-tests/_testing.cj")

// Test: Built-in Option type (Some, None)
// Validates isSome/isNone, getOrThrow, getOrDefault, match, coalescing, and ?Type

// --- Check tags ---
let a = Some(42)
let b = None

expectTrue(a.isSome(), "a.isSome()")
expectFalse(a.isNone(), "a.isNone()")
expectFalse(b.isSome(), "b.isSome()")
expectTrue(b.isNone(), "b.isNone()")

// --- getOrThrow ---
expectEq(a.getOrThrow(), 42, "a.getOrThrow()")

// --- getOrDefault ---
expectEq(a.getOrDefault({ => 0 }), 42, "a.getOrDefault")
expectEq(b.getOrDefault({ => 0 }), 0, "b.getOrDefault")

// --- Pattern matching with Option ---
var matchA: String = ""
match (a) {
  case Some(v) => matchA = "Some: ${v}"
  case None => matchA = "None"
}
expectEq(matchA, "Some: 42", "match a")

var matchB: String = ""
match (b) {
  case Some(v) => matchB = "Some: ${v}"
  case None => matchB = "None"
}
expectEq(matchB, "None", "match b")

// --- Coalescing operator ?? ---
let x = a ?? 0
expectEq(x, 42, "a ?? 0")
let y = b ?? 99
expectEq(y, 99, "b ?? 99")

// --- ?Type in type annotations ---
let c: ?Int64 = Some(10)
let d: ?String = None
expectEq(c.getOrThrow(), 10, "c.getOrThrow()")

if (!__test_failed) {
    println("PASS: 26_option_type")
}
