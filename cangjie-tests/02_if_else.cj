// Test: Control flow - if, else if, else
// Validates basic if, if-else, if-else if-else chains, nested if, and equality checks.

let x = 15

// -- Section: basic if --
var result = ""
if (x > 10) {
  result = "x > 10"
}
if (result != "x > 10") { println("FAIL: basic if expected 'x > 10', got '${result}'"); return () }

// -- Section: if-else --
var result2 = ""
if (x > 20) {
  result2 = "big"
} else {
  result2 = "not big"
}
if (result2 != "not big") { println("FAIL: if-else expected 'not big', got '${result2}'"); return () }

// -- Section: if-else if-else chain --
var result3 = ""
if (x > 100) {
  result3 = "huge"
} else if (x > 50) {
  result3 = "large"
} else if (x > 10) {
  result3 = "medium"
} else {
  result3 = "small"
}
if (result3 != "medium") { println("FAIL: else-if chain expected 'medium', got '${result3}'"); return () }

// -- Section: nested if --
var result4 = ""
if (x > 0) {
  if (x > 10) {
    result4 = "positive and > 10"
  } else {
    result4 = "positive and <= 10"
  }
}
if (result4 != "positive and > 10") { println("FAIL: nested if expected 'positive and > 10', got '${result4}'"); return () }

// -- Section: equality check --
var result5 = ""
if (x == 15) {
  result5 = "x is 15"
}
if (result5 != "x is 15") { println("FAIL: equality check expected 'x is 15', got '${result5}'"); return () }

println("PASS: 02_if_else")
