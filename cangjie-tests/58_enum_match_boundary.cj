dofile("cangjie-tests/_testing.cj")

// Test: Enum and match advanced edge cases

// --- Section: Enum with no constructors body used for match ---
enum Direction {
    | North
    | South
    | East
    | West
}

func dirToString(d: Direction): String {
    match (d) {
        case North => return "N"
        case South => return "S"
        case East => return "E"
        case West => return "W"
    }
}
expectEq(dirToString(North), "N", "match North")
expectEq(dirToString(South), "S", "match South")
expectEq(dirToString(East), "E", "match East")
expectEq(dirToString(West), "W", "match West")

// --- Section: Enum with single constructor ---
enum Wrapper {
    | Value(Int64)
}

let w = Value(99)
var wResult = 0
match (w) {
    case Value(v) => wResult = v
}
expectEq(wResult, 99, "single constructor enum match")

// --- Section: Match with wildcard as only pattern ---
func classify(x: Int64): String {
    match (x) {
        case _ => return "anything"
    }
}
expectEq(classify(42), "anything", "wildcard only match")
expectEq(classify(0), "anything", "wildcard only match zero")

// --- Section: Match with constant strings ---
func greetByLang(lang: String): String {
    match (lang) {
        case "en" => return "Hello"
        case "zh" => return "你好"
        case "es" => return "Hola"
        case _ => return "???"
    }
}
expectEq(greetByLang("en"), "Hello", "match string en")
expectEq(greetByLang("zh"), "你好", "match string zh")
expectEq(greetByLang("es"), "Hola", "match string es")
expectEq(greetByLang("fr"), "???", "match string wildcard")

// --- Section: Match with negative numbers ---
func signOf(n: Int64): String {
    match (n) {
        case 0 => return "zero"
        case _ => if (n > 0) { return "positive" } else { return "negative" }
    }
}
expectEq(signOf(0), "zero", "sign of 0")
expectEq(signOf(5), "positive", "sign of 5")
expectEq(signOf(-3), "negative", "sign of -3")

// --- Section: Recursive enum evaluation ---
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Mul(Expr, Expr)
    | Neg(Expr)
}

func eval(e: Expr): Int64 {
    match (e) {
        case Num(n) => return n
        case Add(a, b) => return eval(a) + eval(b)
        case Mul(a, b) => return eval(a) * eval(b)
        case Neg(a) => return 0 - eval(a)
    }
}

// (2 + 3) * 4 = 20
let expr1 = Mul(Add(Num(2), Num(3)), Num(4))
expectEq(eval(expr1), 20, "recursive enum (2+3)*4")

// Neg(5) = -5
let expr2 = Neg(Num(5))
expectEq(eval(expr2), -5, "recursive enum Neg(5)")

// Add(Neg(3), Num(10)) = 7
let expr3 = Add(Neg(Num(3)), Num(10))
expectEq(eval(expr3), 7, "recursive enum Add(Neg(3), 10)")

// --- Section: Enum member function ---
enum Shape {
    | Circle(Float64)
    | Rect(Float64, Float64)

    func area(): Float64 {
        match (this) {
            case Circle(r) => return 3.14159 * r * r
            case Rect(w, h) => return w * h
        }
    }
}

let c = Circle(1.0)
expectTrue(c.area() > 3.14 && c.area() < 3.15, "circle area ~3.14")
let r = Rect(3.0, 4.0)
expectEq(r.area(), 12.0, "rect area 3*4")

// --- Section: Match as expression ---
let dayNum = 3
let dayName = match (dayNum) {
    case 1 => "Monday"
    case 2 => "Tuesday"
    case 3 => "Wednesday"
    case _ => "Other"
}
expectEq(dayName, "Wednesday", "match as expression")

// --- Section: Match expression with no matching branch ---
let noMatch = match (999) {
    case 1 => "one"
    case 2 => "two"
}
expectNil(noMatch, "match expression no match returns nil")

// --- Section: Enum qualified access ---
let north = Direction.North
expectEq(dirToString(north), "N", "qualified enum access Direction.North")

if (!__test_failed) {
    println("PASS: 58_enum_match_boundary")
}
