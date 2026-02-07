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
if (ifLetMatched != true) { println("FAIL: if-let Some(42) should match"); return () }
if (ifLetVal != 42) { println("FAIL: if-let v expected 42, got ${ifLetVal}"); return () }

// --- if let with None ---
let opt2 = None
var elseHit = false
if (let Some(v) <- opt2) {
  println("FAIL: should not match None"); return ()
} else {
  elseHit = true
}
if (elseHit != true) { println("FAIL: else branch should be taken for None"); return () }

// --- if-let with && logical condition (match and condition true) ---
let opt3 = Some(42)
var andOk = false
if (let Some(v) <- opt3 && v > 10) {
  andOk = true
}
if (andOk != true) { println("FAIL: && with v=42 > 10 should match"); return () }

// --- if-let with && logical condition (match but condition false) ---
let opt4 = Some(3)
var andFalse = false
if (let Some(v) <- opt4 && v > 10) {
  println("FAIL: && with v=3 > 10 should not match"); return ()
} else {
  andFalse = true
}
if (andFalse != true) { println("FAIL: && false branch should be taken"); return () }

// --- if-let with && but None ---
let opt5 = None
var andNoMatch = false
if (let Some(v) <- opt5 && true) {
  println("FAIL: && with None should not match"); return ()
} else {
  andNoMatch = true
}
if (andNoMatch != true) { println("FAIL: && no match branch should be taken"); return () }

// --- if-let with || (match succeeds) ---
let opt6 = Some(5)
var orMatchOk = false
if (let Some(v) <- opt6 || false) {
  orMatchOk = true
}
if (orMatchOk != true) { println("FAIL: || match should succeed"); return () }

// --- if-let with || (no match but fallback true) ---
let opt7 = None
var orFallback = false
if (let Some(v) <- opt7 || true) {
  orFallback = true
}
if (orFallback != true) { println("FAIL: || fallback true should enter body"); return () }

// --- if-let with || (both false) ---
let opt8 = None
var orBothFalse = false
if (let Some(v) <- opt8 || false) {
  println("FAIL: || both false should not match"); return ()
} else {
  orBothFalse = true
}
if (orBothFalse != true) { println("FAIL: || both false else should be taken"); return () }

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
if (whileLetResult != "210") { println("FAIL: while-let expected '210', got '${whileLetResult}'"); return () }

println("PASS: 27_if_let_while_let")
