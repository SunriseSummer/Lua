// if let pattern matching
let opt1 = Some(42)
if (let Some(v) <- opt1) {
  println("got: ${v}")
}

let opt2 = None
if (let Some(v) <- opt2) {
  println("should not print")
} else {
  println("was None")
}

// while let pattern matching
var count = 3
func getNext(): ?Int64 {
  if (count > 0) {
    count = count - 1
    return Some(count)
  }
  return None
}

// Note: for while let, the expression is re-evaluated each iteration
while (let Some(v) <- getNext()) {
  println("while got: ${v}")
}

println("PASS: 27_if_let_while_let")
