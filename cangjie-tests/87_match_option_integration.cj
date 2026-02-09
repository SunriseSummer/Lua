dofile("cangjie-tests/_testing.cj")

// Test: Match expressions returning Option values and Option + match integration

// --- Section: Match returning Option values ---
enum Color { | Red | Green | Blue }

func colorToOption(c: Color): ?String {
    return match (c) {
        case Red => Some("red")
        case Green => Some("green")
        case _ => None
    }
}

let r = colorToOption(Red)
expectTrue(r.isSome(), "colorToOption Red isSome")
expectEq(r.getOrThrow(), "red", "colorToOption Red value")

let g = colorToOption(Green)
expectEq(g.getOrThrow(), "green", "colorToOption Green value")

let b = colorToOption(Blue)
expectTrue(b.isNone(), "colorToOption Blue isNone")

// --- Section: Match result used with ?? operator ---
let fallback = colorToOption(Blue) ?? "unknown"
expectEq(fallback, "unknown", "match result ?? fallback")

let direct = colorToOption(Red) ?? "unknown"
expectEq(direct, "red", "match result ?? direct value")

// --- Section: Match on Option values ---
func describeOption(opt: ?Int64): String {
    return match (opt) {
        case Some(v) => "has: ${v}"
        case None => "empty"
        case _ => "other"
    }
}

expectEq(describeOption(Some(42)), "has: 42", "match Option Some")
expectEq(describeOption(None), "empty", "match Option None")

// --- Section: Match result in arithmetic expression ---
enum Value { | Num(Int64) | Zero }

func getValue(v: Value): Int64 {
    return match (v) {
        case Num(n) => n
        case Zero => 0
        case _ => -1
    }
}

let sum = getValue(Num(10)) + getValue(Num(20)) + getValue(Zero)
expectEq(sum, 30, "match result in arithmetic")

// --- Section: Match as function argument ---
func doubleIt(x: Int64): Int64 { return x * 2 }

let doubled = doubleIt(match (Num(5)) {
    case Num(n) => n
    case _ => 0
})
expectEq(doubled, 10, "match as function argument")

// --- Section: Match result assigned to variable ---
let assigned: Int64 = match (Num(7)) {
    case Num(n) => n * 3
    case _ => 0
}
expectEq(assigned, 21, "match result assigned to variable")

// --- Section: Nested match with Option ---
enum Status { | Active(Int64) | Inactive }

func processStatus(s: Status): ?String {
    return match (s) {
        case Active(level) => match (level > 5) {
            case true => Some("high")
            case false => Some("low")
            case _ => None
        }
        case Inactive => None
        case _ => None
    }
}

let high = processStatus(Active(10))
expectTrue(high.isSome(), "nested match high isSome")
expectEq(high.getOrThrow(), "high", "nested match high value")

let low = processStatus(Active(3))
expectEq(low.getOrThrow(), "low", "nested match low value")

let inactive = processStatus(Inactive)
expectTrue(inactive.isNone(), "nested match inactive isNone")

// --- Section: ?? in match case body ---
func optOrDefault(opt: ?Int64): Int64 {
    return match (opt.isSome()) {
        case true => opt.getOrThrow()
        case false => -1
        case _ => -1
    }
}

expectEq(optOrDefault(Some(99)), 99, "option in match body Some")
expectEq(optOrDefault(None), -1, "option in match body None")

if (!__test_failed) {
    println("PASS: 87_match_option_integration")
}
