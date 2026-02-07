dofile("cangjie-tests/_testing.cj")

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
let redResult = describeColor(Red)
expectEq(redResult, "It is red", "describeColor(Red)")
let greenResult = describeColor(Green)
expectEq(greenResult, "It is green", "describeColor(Green)")
let blueResult = describeColor(Blue(200))
expectEq(blueResult, "It is blue with value 200", "describeColor(Blue(200))")

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
let num0 = describeNumber(0)
expectEq(num0, "zero", "describeNumber(0)")
let num1 = describeNumber(1)
expectEq(num1, "one", "describeNumber(1)")
let num42 = describeNumber(42)
expectEq(num42, "the answer", "describeNumber(42)")
let num99 = describeNumber(99)
expectEq(num99, "some number: 99", "describeNumber(99)")

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
expectEq(rectArea, 12.0, "rect area")
expectEq(triArea, 0.0, "triangle area")

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
expectEq(evalResult, 9, "(1+2)*(4-1)")

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
expectEq(someResult, 42, "getOrDefault(Some(42),0)")
expectEq(noneResult, -1, "getOrDefault(None,-1)")

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
expectEq(dogResult, "Rex barks!", "describeAnimal(Dog)")
let catResult = describeAnimal(Cat("Whiskers"))
expectEq(catResult, "Whiskers meows!", "describeAnimal(Cat)")
let animalResult = describeAnimal(Animal("Parrot"))
expectEq(animalResult, "Parrot is generic", "describeAnimal(Animal)")

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
expectEq(pairResult1, "pair: 10, 20", "processPair(10,20)")
let pairResult2 = processPair(("hello", "world"))
expectEq(pairResult2, "pair: hello, world", "processPair(hello,world)")

// --- Tuple pattern with wildcard ---
func getFirst(t) {
  match (t) {
    case (x, _) =>
      return x
  }
  return nil
}

let firstResult = getFirst((42, 99))
expectEq(firstResult, 42, "getFirst((42,99))")

if (!__test_failed) {
    println("PASS: 13_match")
}
