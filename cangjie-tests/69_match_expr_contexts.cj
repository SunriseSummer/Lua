dofile("cangjie-tests/_testing.cj")

// Test: Match expressions used in various expression contexts

// -- Setup --
enum Fruit {
    | Apple
    | Banana
    | Cherry(Int64)
}

// -- Section: Match as assignment --
let v1 = match (2) {
    case 1 => "one"
    case 2 => "two"
    case _ => "other"
}
expectEq(v1, "two", "match assign constant")

// -- Section: Match with enum as assignment --
let v2 = match (Cherry(5)) {
    case Apple => "apple"
    case Cherry(n) => "cherry ${n}"
    case _ => "unknown"
}
expectEq(v2, "cherry 5", "match assign enum")

// -- Section: Match as function argument --
func double(x) { return x * 2 }
let v3 = double(match (3) {
    case 3 => 10
    case _ => 0
})
expectEq(v3, 20, "match as func arg")

// -- Section: Match in arithmetic --
let v4 = match (1) {
    case 1 => 100
    case _ => 0
} + 50
expectEq(v4, 150, "match + arithmetic")

// -- Section: Nested match --
let outer = 2
let inner = 1
let v5 = match (outer) {
    case 2 =>
        match (inner) {
            case 1 => "two-one"
            case _ => "two-other"
        }
    case _ => "other"
}
expectEq(v5, "two-one", "nested match")

// -- Section: Match inside if condition --
let cond_val = match (10) {
    case 10 => true
    case _ => false
}
if (cond_val) {
    expectTrue(true, "match in condition true path")
} else {
    expectTrue(false, "match in condition should be true")
}

// -- Section: Match with block expression body --
let v6 = match (3) {
    case 3 =>
        let a = 10
        let b = 20
        a + b
    case _ => 0
}
expectEq(v6, 30, "match with block body")

// -- Section: Match with wildcard as expression --
let v7 = match (999) {
    case 1 => "one"
    case _ => "wildcard"
}
expectEq(v7, "wildcard", "match wildcard expr")

// -- Section: Match with tuple pattern --
let v8 = match ((3, 4)) {
    case (a, b) => a + b
}
expectEq(v8, 7, "match tuple pattern expr")

// -- Section: Match returning different types --
let v9 = match (0) {
    case 0 => "zero"
    case _ => "nonzero"
}
expectEq(v9, "zero", "match string return")

// -- Section: Match no-match returns nil --
let v10 = match (42) {
    case 1 => "one"
    case 2 => "two"
}
expectNil(v10, "match no-match is nil")

// -- Section: Match result stored and used later --
func classify(n) {
    return match (n) {
        case 0 => "zero"
        case 1 => "one"
        case _ => "many"
    }
}
expectEq(classify(0), "zero", "classify 0")
expectEq(classify(1), "one", "classify 1")
expectEq(classify(99), "many", "classify 99")

// -- Section: Match result in string interpolation --
let v11val = match (5) {
    case 5 => "five"
    case _ => "?"
}
let v11 = "result: ${v11val}"
expectEq(v11, "result: five", "match result in interpolation")

if (!__test_failed) {
    println("PASS: 69_match_expr_contexts")
}
