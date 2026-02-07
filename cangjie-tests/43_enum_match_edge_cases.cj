dofile("cangjie-tests/_testing.cj")

// Test: Enum and pattern matching edge cases

// --- Enum with single constructor ---
enum Single {
    | Only(Int64)
}
let s = Only(42)
var sval = 0
match (s) {
    case Only(v) => sval = v
}
expectEq(sval, 42, "single constructor enum")

// --- Enum with many constructors ---
enum Token {
    | Number(Int64)
    | Text(String)
    | Plus
    | Minus
    | Star
    | Slash
    | EOF
}
let tok = Number(42)
var tokStr = ""
match (tok) {
    case Number(n) => tokStr = "num:${n}"
    case Text(s) => tokStr = "text:${s}"
    case Plus => tokStr = "+"
    case Minus => tokStr = "-"
    case Star => tokStr = "*"
    case Slash => tokStr = "/"
    case EOF => tokStr = "eof"
}
expectEq(tokStr, "num:42", "many constructors match")

// --- Pattern matching with wildcard fallthrough ---
func classify(n: Int64): String {
    match (n) {
        case 0 => return "zero"
        case 1 => return "one"
        case 2 => return "two"
        case _ => return "other"
    }
    return "unreachable"
}
expectEq(classify(0), "zero", "classify 0")
expectEq(classify(1), "one", "classify 1")
expectEq(classify(2), "two", "classify 2")
expectEq(classify(100), "other", "classify 100")
expectEq(classify(-1), "other", "classify -1")

// --- Nested enum matching ---
enum Outer {
    | Inner(Int64, Int64)
    | Flat(Int64)
}
func sumOuter(o): Int64 {
    match (o) {
        case Inner(a, b) => return a + b
        case Flat(v) => return v
    }
    return 0
}
expectEq(sumOuter(Inner(3, 4)), 7, "nested enum inner")
expectEq(sumOuter(Flat(10)), 10, "nested enum flat")

// --- Match with string patterns ---
func greet(lang: String): String {
    match (lang) {
        case "en" => return "Hello"
        case "zh" => return "你好"
        case "ja" => return "こんにちは"
        case _ => return "Hi"
    }
    return ""
}
expectEq(greet("en"), "Hello", "match string en")
expectEq(greet("zh"), "你好", "match string zh")
expectEq(greet("fr"), "Hi", "match string wildcard")

// --- Option type edge cases ---
let some1 = Some(0)
expectTrue(some1.isSome(), "Some(0) isSome")
expectEq(some1.getOrThrow(), 0, "Some(0) getOrThrow")

let some2 = Some(-1)
expectEq(some2.getOrThrow(), -1, "Some(-1) getOrThrow")

let none1 = None
expectTrue(none1.isNone(), "None isNone")

// --- Coalescing operator chains ---
let opt_a = None
let opt_b = None
let opt_c = Some(42)
let result = opt_a ?? opt_b ?? opt_c ?? 0
expectEq(result, 42, "chained ??")

let all_none = opt_a ?? opt_b ?? 99
expectEq(all_none, 99, "all none ??")

// --- Enum method calling ---
enum Shape {
    | Circle(Float64)
    | Rect(Float64, Float64)

    func area(): Float64 {
        match (this) {
            case Circle(r) => return 3.14159 * r * r
            case Rect(w, h) => return w * h
        }
        return 0.0
    }

    func name(): String {
        match (this) {
            case Circle(r) => return "circle"
            case Rect(w, h) => return "rect"
        }
        return "unknown"
    }
}

let circle = Circle(5.0)
expectEq(circle.name(), "circle", "enum method name")

let rect = Rect(3.0, 4.0)
expectEq(rect.area(), 12.0, "enum method area")

// --- Match with tuple patterns ---
func addPair(p): Int64 {
    match (p) {
        case (a, b) => return a + b
    }
    return 0
}
expectEq(addPair((3, 4)), 7, "tuple match add")
expectEq(addPair((0, 0)), 0, "tuple match zero")
expectEq(addPair((-1, 1)), 0, "tuple match cancel")

// --- Match with type pattern ---
class Animal {
    var name: String
    init(name: String) { this.name = name }
}
class Dog <: Animal {
    init(name: String) { this.name = name }
}
class Cat <: Animal {
    init(name: String) { this.name = name }
}

func animalType(a): String {
    match (a) {
        case d: Dog => return "dog"
        case c: Cat => return "cat"
        case _ => return "unknown"
    }
    return ""
}
expectEq(animalType(Dog("Rex")), "dog", "type pattern dog")
expectEq(animalType(Cat("Kitty")), "cat", "type pattern cat")

if (!__test_failed) {
    println("PASS: 43_enum_match_edge_cases")
}
