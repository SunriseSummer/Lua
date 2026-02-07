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

// if-let with && logical condition
let opt3 = Some(42)
if (let Some(v) <- opt3 && v > 10) {
  println("&& ok: ${v}")
}

let opt4 = Some(3)
if (let Some(v) <- opt4 && v > 10) {
  println("should not print")
} else {
  println("&& false: v too small")
}

let opt5 = None
if (let Some(v) <- opt5 && true) {
  println("should not print")
} else {
  println("&& no match")
}

// if-let with || logical condition
let opt6 = Some(5)
if (let Some(v) <- opt6 || false) {
  println("|| match ok")
}

let opt7 = None
if (let Some(v) <- opt7 || true) {
  println("|| fallback true")
}

let opt8 = None
if (let Some(v) <- opt8 || false) {
  println("should not print")
} else {
  println("|| both false")
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
