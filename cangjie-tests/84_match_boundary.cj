dofile("cangjie-tests/_testing.cj")

// Test: Match pattern edge cases — wildcard-only, single case, strings, booleans,
// integers, nil, match as expression, match in variable init, nested match

// --- Section: Match with only wildcard case ---
func wildcardOnly(x): String {
    return match (x) {
        case _ => "wildcard"
    }
}
expectEq(wildcardOnly(1), "wildcard", "wildcard-only int")
expectEq(wildcardOnly("hi"), "wildcard", "wildcard-only string")
expectEq(wildcardOnly(nil), "wildcard", "wildcard-only nil")

// --- Section: Single constant case and wildcard ---
func singleConst(x): String {
    return match (x) {
        case 42 => "found it"
        case _ => "other"
    }
}
expectEq(singleConst(42), "found it", "single const match")
expectEq(singleConst(0), "other", "single const no match")
expectEq(singleConst("42"), "other", "single const type mismatch")

// --- Section: Match on string constants ---
func matchStr(s): String {
    return match (s) {
        case "" => "empty"
        case "a" => "single char"
        case "héllo" => "unicode"
        case "hello world" => "multi word"
        case _ => "other string"
    }
}
expectEq(matchStr(""), "empty", "match empty string")
expectEq(matchStr("a"), "single char", "match single char")
expectEq(matchStr("héllo"), "unicode", "match unicode string")
expectEq(matchStr("hello world"), "multi word", "match multi word")
expectEq(matchStr("xyz"), "other string", "match string wildcard")

// --- Section: Match on boolean true/false ---
func matchBool(b): String {
    return match (b) {
        case true => "yes"
        case false => "no"
    }
}
expectEq(matchBool(true), "yes", "match true")
expectEq(matchBool(false), "no", "match false")

// --- Section: Match on integer edge values ---
func matchInt(n): String {
    return match (n) {
        case 0 => "zero"
        case 1 => "one"
        case 999999 => "big"
        case _ =>
            if (n < 0) {
                return "negative"
            }
            return "other"
    }
}
expectEq(matchInt(0), "zero", "match int zero")
expectEq(matchInt(1), "one", "match int one")
expectEq(matchInt(-1), "negative", "match int negative via wildcard")
expectEq(matchInt(999999), "big", "match int large positive")
expectEq(matchInt(5), "other", "match int other")

// --- Section: Match on nil value ---
func matchNil(x): String {
    return match (x) {
        case nil => "is nil"
        case _ => "not nil"
    }
}
expectEq(matchNil(nil), "is nil", "match nil")
expectEq(matchNil(0), "not nil", "match nil non-nil zero")
expectEq(matchNil(""), "not nil", "match nil non-nil empty str")

// --- Section: Match expression used as function argument ---
func identity(s: String): String {
    return s
}
let argResult = identity(match (3) {
    case 1 => "one"
    case 2 => "two"
    case 3 => "three"
    case _ => "other"
})
expectEq(argResult, "three", "match as function argument")

// --- Section: Match expression in variable initialization ---
let initVal = match (true) {
    case true => 100
    case false => 0
}
expectEq(initVal, 100, "match in variable init")

let initVal2 = match ("test") {
    case "test" => "matched"
    case _ => "nope"
}
expectEq(initVal2, "matched", "match string in variable init")

// --- Section: Nested match expressions ---
func nestedMatch(x: Int64): String {
    return match (x > 0) {
        case true => match (x > 100) {
            case true => "large"
            case false => "small"
        }
        case false => match (x == 0) {
            case true => "zero"
            case false => "negative"
        }
    }
}
expectEq(nestedMatch(200), "large", "nested match large")
expectEq(nestedMatch(50), "small", "nested match small")
expectEq(nestedMatch(0), "zero", "nested match zero")
expectEq(nestedMatch(-5), "negative", "nested match negative")

// --- Section: Match with enum in nested context ---
enum Tag {
    | A
    | B(Int64)
}

func classifyTag(t): String {
    return match (t) {
        case A => "plain"
        case B(v) => match (v > 0) {
            case true => "positive B(${v})"
            case false => "non-positive B(${v})"
        }
    }
}
expectEq(classifyTag(A), "plain", "nested match enum A")
expectEq(classifyTag(B(10)), "positive B(10)", "nested match enum B positive")
expectEq(classifyTag(B(-3)), "non-positive B(-3)", "nested match enum B negative")

if (__test_failed) {
    println("FAIL: 84_match_boundary")
} else {
    println("PASS: 84_match_boundary")
}
