// Test: Built-in Option type (Some, None)
// Validates isSome/isNone, getOrThrow, getOrDefault, match, coalescing, and ?Type

// --- Check tags ---
let a = Some(42)
let b = None

if (a.isSome() != true) { println("FAIL: a.isSome() expected true"); return () }
if (a.isNone() != false) { println("FAIL: a.isNone() expected false"); return () }
if (b.isSome() != false) { println("FAIL: b.isSome() expected false"); return () }
if (b.isNone() != true) { println("FAIL: b.isNone() expected true"); return () }

// --- getOrThrow ---
if (a.getOrThrow() != 42) { println("FAIL: a.getOrThrow() expected 42, got ${a.getOrThrow()}"); return () }

// --- getOrDefault ---
if (a.getOrDefault({ => 0 }) != 42) { println("FAIL: a.getOrDefault expected 42"); return () }
if (b.getOrDefault({ => 0 }) != 0) { println("FAIL: b.getOrDefault expected 0"); return () }

// --- Pattern matching with Option ---
var matchA: String = ""
match (a) {
  case Some(v) => matchA = "Some: ${v}"
  case None => matchA = "None"
}
if (matchA != "Some: 42") { println("FAIL: match a expected 'Some: 42', got '${matchA}'"); return () }

var matchB: String = ""
match (b) {
  case Some(v) => matchB = "Some: ${v}"
  case None => matchB = "None"
}
if (matchB != "None") { println("FAIL: match b expected 'None', got '${matchB}'"); return () }

// --- Coalescing operator ?? ---
let x = a ?? 0
if (x != 42) { println("FAIL: a ?? 0 expected 42, got ${x}"); return () }
let y = b ?? 99
if (y != 99) { println("FAIL: b ?? 99 expected 99, got ${y}"); return () }

// --- ?Type in type annotations ---
let c: ?Int64 = Some(10)
let d: ?String = None
if (c.getOrThrow() != 10) { println("FAIL: c.getOrThrow() expected 10, got ${c.getOrThrow()}"); return () }

println("PASS: 26_option_type")
