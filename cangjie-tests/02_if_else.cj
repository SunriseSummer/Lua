dofile("cangjie-tests/_testing.cj")

// Test: Control flow - if, else if, else

let x = 15

// -- Section: basic if --
var result = ""
if (x > 10) {
  result = "x > 10"
}
expectEq(result, "x > 10", "basic if")

// -- Section: if-else --
var result2 = ""
if (x > 20) {
  result2 = "big"
} else {
  result2 = "not big"
}
expectEq(result2, "not big", "if-else")

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
expectEq(result3, "medium", "else-if chain")

// -- Section: nested if --
var result4 = ""
if (x > 0) {
  if (x > 10) {
    result4 = "positive and > 10"
  } else {
    result4 = "positive and <= 10"
  }
}
expectEq(result4, "positive and > 10", "nested if")

// -- Section: equality check --
var result5 = ""
if (x == 15) {
  result5 = "x is 15"
}
expectEq(result5, "x is 15", "equality check")

if (!__test_failed) {
    println("PASS: 02_if_else")
}
