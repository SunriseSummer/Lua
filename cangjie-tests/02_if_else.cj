// Test: Control flow - if, else if, else

let x = 15

// Basic if (parentheses required)
if (x > 10) {
  println("x > 10")
}

// if-else
if (x > 20) {
  println("big")
} else {
  println("not big")
}

// if-else if-else
if (x > 100) {
  println("huge")
} else if (x > 50) {
  println("large")
} else if (x > 10) {
  println("medium")
} else {
  println("small")
}

// Nested if
if (x > 0) {
  if (x > 10) {
    println("positive and > 10")
  } else {
    println("positive and <= 10")
  }
}

// if with equality check
if (x == 15) {
  println("x is 15")
}

println("PASS: 02_if_else")
