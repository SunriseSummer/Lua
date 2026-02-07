dofile("cangjie-tests/_testing.cj")

// Test: if-let and while-let pattern matching
// Validates conditional pattern matching with Some/None, &&, ||, and while-let loops

// --- if let with Some ---
let opt1 = Some(42)
var ifLetVal: Int64 = 0
var ifLetMatched = false
if (let Some(v) <- opt1) {
  ifLetVal = v
  ifLetMatched = true
}
expectTrue(ifLetMatched, "if-let Some(42) should match")
expectEq(ifLetVal, 42, "if-let v")

// --- if let with None ---
let opt2 = None
var elseHit = false
if (let Some(v) <- opt2) {
  __test_failed = true
  println("FAIL: should not match None")
} else {
  elseHit = true
}
expectTrue(elseHit, "else branch should be taken for None")

// --- if-let with && logical condition (match and condition true) ---
let opt3 = Some(42)
var andOk = false
if (let Some(v) <- opt3 && v > 10) {
  andOk = true
}
expectTrue(andOk, "&& with v=42 > 10 should match")

// --- if-let with && logical condition (match but condition false) ---
let opt4 = Some(3)
var andFalse = false
if (let Some(v) <- opt4 && v > 10) {
  __test_failed = true
  println("FAIL: && with v=3 > 10 should not match")
} else {
  andFalse = true
}
expectTrue(andFalse, "&& false branch should be taken")

// --- if-let with && but None ---
let opt5 = None
var andNoMatch = false
if (let Some(v) <- opt5 && true) {
  __test_failed = true
  println("FAIL: && with None should not match")
} else {
  andNoMatch = true
}
expectTrue(andNoMatch, "&& no match branch should be taken")

// --- if-let with || (match succeeds) ---
let opt6 = Some(5)
var orMatchOk = false
if (let Some(v) <- opt6 || false) {
  orMatchOk = true
}
expectTrue(orMatchOk, "|| match should succeed")

// --- if-let with || (no match but fallback true) ---
let opt7 = None
var orFallback = false
if (let Some(v) <- opt7 || true) {
  orFallback = true
}
expectTrue(orFallback, "|| fallback true should enter body")

// --- if-let with || (both false) ---
let opt8 = None
var orBothFalse = false
if (let Some(v) <- opt8 || false) {
  __test_failed = true
  println("FAIL: || both false should not match")
} else {
  orBothFalse = true
}
expectTrue(orBothFalse, "|| both false else should be taken")

// --- while let pattern matching ---
var count = 3
func getNext(): ?Int64 {
  if (count > 0) {
    count = count - 1
    return Some(count)
  }
  return None
}

var whileLetResult: String = ""
while (let Some(v) <- getNext()) {
  whileLetResult = whileLetResult + tostring(v)
}
expectEq(whileLetResult, "210", "while-let result")

if (!__test_failed) {
    println("PASS: 27_if_let_while_let")
}
