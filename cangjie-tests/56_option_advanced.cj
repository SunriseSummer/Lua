dofile("cangjie-tests/_testing.cj")

// Test: Option type advanced edge cases

// --- Section: Nested Option ---
let nested = Some(Some(42))
expectTrue(nested.isSome(), "nested Some is Some")
let inner = nested.getOrThrow()
expectTrue(inner.isSome(), "inner is Some")
expectEq(inner.getOrThrow(), 42, "nested unwrap")

// --- Section: Option with string ---
let os: ?String = Some("hello")
expectEq(os.getOrThrow(), "hello", "Option<String> getOrThrow")
let osNone: ?String = None
expectEq(osNone ?? "default", "default", "Option<String> ?? default")

// --- Section: Option with Bool value ---
let ob = Some(false)
expectTrue(ob.isSome(), "Some(false) is Some")
expectEq(ob.getOrThrow(), false, "Some(false) getOrThrow is false")

// --- Section: Option with zero ---
let oz = Some(0)
expectTrue(oz.isSome(), "Some(0) is Some")
expectEq(oz.getOrThrow(), 0, "Some(0) getOrThrow is 0")
expectEq(oz ?? 99, 0, "Some(0) ?? 99 is 0")

// --- Section: Chained coalescing ---
let n1: ?Int64 = None
let n2: ?Int64 = None
let n3: ?Int64 = Some(77)
let chainResult = n1 ?? n2 ?? n3 ?? 0
expectEq(chainResult, 77, "chained ?? finds first Some")

// --- Section: All None chained coalescing ---
let nn1: ?Int64 = None
let nn2: ?Int64 = None
let nn3: ?Int64 = None
let allNone = nn1 ?? nn2 ?? nn3 ?? -1
expectEq(allNone, -1, "all None chained ?? returns default")

// --- Section: match with Some containing complex values ---
let optArr = Some([1, 2, 3])
var matchResult = ""
match (optArr) {
    case Some(v) =>
        matchResult = "array size ${v.size}"
    case None =>
        matchResult = "none"
}
expectEq(matchResult, "array size 3", "match Option with array")

// --- Section: getOrDefault with computation ---
let optNone: ?Int64 = None
let computed = optNone.getOrDefault({ => 5 * 10 + 3 })
expectEq(computed, 53, "getOrDefault with computation")

// --- Section: Option in if-let ---
let optVal = Some(100)
var ifLetResult = 0
if (let Some(v) <- optVal) {
    ifLetResult = v
}
expectEq(ifLetResult, 100, "if-let unwraps Some")

var ifLetElse = ""
let optEmpty: ?Int64 = None
if (let Some(v) <- optEmpty) {
    ifLetElse = "found"
} else {
    ifLetElse = "not found"
}
expectEq(ifLetElse, "not found", "if-let else branch for None")

// --- Section: while-let iteration ---
var items = [Some(1), Some(2), Some(3), None]
var whileLetSum = 0
var idx = 0
while (let Some(v) <- items[idx]) {
    whileLetSum = whileLetSum + v
    idx = idx + 1
}
expectEq(whileLetSum, 6, "while-let sum of Some values")

// --- Section: Option as function return ---
func findPositive(n: Int64): ?Int64 {
    if (n > 0) {
        return Some(n)
    }
    return None
}
expectTrue(findPositive(5).isSome(), "findPositive(5) is Some")
expectTrue(findPositive(-3).isNone(), "findPositive(-3) is None")
expectEq(findPositive(5).getOrThrow(), 5, "findPositive(5) value")
expectEq(findPositive(-3) ?? 0, 0, "findPositive(-3) ?? 0")

// --- Section: if-let with && condition ---
let optGt = Some(42)
var guardResult = ""
if (let Some(v) <- optGt && v > 10) {
    guardResult = "big: ${v}"
}
expectEq(guardResult, "big: 42", "if-let with && guard")

var guardFail = "untouched"
if (let Some(v) <- optGt && v > 100) {
    guardFail = "should not enter"
}
expectEq(guardFail, "untouched", "if-let with && guard fails")

if (!__test_failed) {
    println("PASS: 56_option_advanced")
}
