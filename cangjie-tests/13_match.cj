// Test: Pattern matching — enum, constant, wildcard, recursive, Option, type, tuple patterns

// === Enum pattern matching (no braces after =>) ===
enum Color {
  | Red
  | Green
  | Blue(Int64)
}

func describeColor(c) {
  match (c) {
    case Red =>
      return "It is red"
    case Green =>
      return "It is green"
    case Blue(val) =>
      return "It is blue with value ${val}"
  }
  return "Unknown"
}

// --- Assert describeColor results ---
if (describeColor(Red) != "It is red") { println("FAIL: describeColor(Red) expected It is red, got ${describeColor(Red)}"); return () }
if (describeColor(Green) != "It is green") { println("FAIL: describeColor(Green) expected It is green, got ${describeColor(Green)}"); return () }
if (describeColor(Blue(200)) != "It is blue with value 200") { println("FAIL: describeColor(Blue(200)) expected It is blue with value 200, got ${describeColor(Blue(200))}"); return () }

// === Constant pattern matching ===
func describeNumber(n) {
  match (n) {
    case 0 =>
      return "zero"
    case 1 =>
      return "one"
    case 42 =>
      return "the answer"
    case _ =>
      return "some number: ${n}"
  }
  return "unknown"
}

// --- Assert describeNumber results ---
if (describeNumber(0) != "zero") { println("FAIL: describeNumber(0) expected zero, got ${describeNumber(0)}"); return () }
if (describeNumber(1) != "one") { println("FAIL: describeNumber(1) expected one, got ${describeNumber(1)}"); return () }
if (describeNumber(42) != "the answer") { println("FAIL: describeNumber(42) expected the answer, got ${describeNumber(42)}"); return () }
if (describeNumber(99) != "some number: 99") { println("FAIL: describeNumber(99) expected some number: 99, got ${describeNumber(99)}"); return () }

// === Wildcard pattern with multi-line body ===
enum Shape {
  | Circle(Float64)
  | Rectangle(Float64, Float64)
  | Triangle(Float64, Float64, Float64)
}

func getArea(s) {
  match (s) {
    case Circle(r) =>
      return 3.14159 * r * r
    case Rectangle(w, h) =>
      return w * h
    case _ =>
      return 0.0
  }
  return 0.0
}

// --- Assert area calculations ---
let circleArea = getArea(Circle(5.0))
let rectArea = getArea(Rectangle(3.0, 4.0))
let triArea = getArea(Triangle(3.0, 4.0, 5.0))
if (rectArea != 12.0) { println("FAIL: rect area expected 12.0, got ${rectArea}"); return () }
if (triArea != 0.0) { println("FAIL: triangle area expected 0.0, got ${triArea}"); return () }

// === Recursive enum with pattern matching ===
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Sub(Expr, Expr)
  | Mul(Expr, Expr)
}

func eval(e) {
  match (e) {
    case Num(n) =>
      return n
    case Add(a, b) =>
      return eval(a) + eval(b)
    case Sub(a, b) =>
      return eval(a) - eval(b)
    case Mul(a, b) =>
      return eval(a) * eval(b)
  }
  return 0
}

// --- Assert (1+2)*(4-1) = 9 ---
let expr1 = Mul(
  Add(Num(1), Num(2)),
  Sub(Num(4), Num(1))
)
let evalResult = eval(expr1)
if (evalResult != 9) { println("FAIL: (1+2)*(4-1) expected 9, got ${evalResult}"); return () }

// === Option type pattern matching ===
enum Option {
  | Some(Int64)
  | None
}

func getOrDefault(opt, default_val) {
  match (opt) {
    case Some(v) =>
      return v
    case None =>
      return default_val
  }
  return default_val
}

// --- Assert getOrDefault results ---
let someResult = getOrDefault(Some(42), 0)
let noneResult = getOrDefault(None, -1)
if (someResult != 42) { println("FAIL: getOrDefault(Some(42),0) expected 42, got ${someResult}"); return () }
if (noneResult != -1) { println("FAIL: getOrDefault(None,-1) expected -1, got ${noneResult}"); return () }

// === Type pattern matching ===
class Animal {
  var name: String
  init(name: String) {
    this.name = name
  }
}

class Dog <: Animal {
  init(name: String) {
    this.name = name
  }
  func bark(): String {
    return "${this.name} barks!"
  }
}

class Cat <: Animal {
  init(name: String) {
    this.name = name
  }
}

func describeAnimal(a) {
  match (a) {
    case d: Dog =>
      return d.bark()
    case c: Cat =>
      return "${c.name} meows!"
    case a: Animal =>
      return "${a.name} is generic"
    case _ =>
      return "not an animal"
  }
  return "unknown"
}

// --- Assert describeAnimal results ---
let dogResult = describeAnimal(Dog("Rex"))
if (dogResult != "Rex barks!") { println("FAIL: describeAnimal(Dog) expected Rex barks!, got ${dogResult}"); return () }
let catResult = describeAnimal(Cat("Whiskers"))
if (catResult != "Whiskers meows!") { println("FAIL: describeAnimal(Cat) expected Whiskers meows!, got ${catResult}"); return () }
let animalResult = describeAnimal(Animal("Parrot"))
if (animalResult != "Parrot is generic") { println("FAIL: describeAnimal(Animal) expected Parrot is generic, got ${animalResult}"); return () }

// === Tuple pattern matching ===
func processPair(p) {
  match (p) {
    case (x, y) =>
      return "pair: ${x}, ${y}"
  }
  return "unknown"
}

// --- Assert processPair results ---
let pairResult1 = processPair((10, 20))
if (pairResult1 != "pair: 10, 20") { println("FAIL: processPair(10,20) expected pair: 10, 20, got ${pairResult1}"); return () }
let pairResult2 = processPair(("hello", "world"))
if (pairResult2 != "pair: hello, world") { println("FAIL: processPair(hello,world) expected pair: hello, world, got ${pairResult2}"); return () }

// --- Tuple pattern with wildcard ---
func getFirst(t) {
  match (t) {
    case (x, _) =>
      return x
  }
  return nil
}

let firstResult = getFirst((42, 99))
if (firstResult != 42) { println("FAIL: getFirst((42,99)) expected 42, got ${firstResult}"); return () }

println("PASS: 13_match")
