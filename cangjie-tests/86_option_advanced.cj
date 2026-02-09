dofile("cangjie-tests/_testing.cj")

// Test: Option type advanced edge cases — different value types, nested Some,
// ?? chaining, getOrDefault, if-let, match, isSome/isNone

// --- Section: Option with Int64 ---
let oi: ?Int64 = Some(42)
expectTrue(oi.isSome(), "Option Int64 isSome")
expectFalse(oi.isNone(), "Option Int64 isNone")
expectEq(oi.getOrThrow(), 42, "Option Int64 getOrThrow")

// --- Section: Option with String ---
let os: ?String = Some("hello")
expectTrue(os.isSome(), "Option String isSome")
expectEq(os.getOrThrow(), "hello", "Option String getOrThrow")
let osNone: ?String = None
expectTrue(osNone.isNone(), "Option String None isNone")

// --- Section: Option with Bool ---
let obTrue: ?Bool = Some(true)
let obFalse: ?Bool = Some(false)
expectTrue(obTrue.isSome(), "Some(true) isSome")
expectTrue(obFalse.isSome(), "Some(false) isSome")
expectEq(obTrue.getOrThrow(), true, "Some(true) getOrThrow")
expectEq(obFalse.getOrThrow(), false, "Some(false) getOrThrow")

// --- Section: Option with Float64 ---
let of: ?Float64 = Some(3.14)
expectTrue(of.isSome(), "Some(3.14) isSome")
expectEq(of.getOrThrow(), 3.14, "Some(3.14) getOrThrow")
let ofNone: ?Float64 = None
expectEq(ofNone ?? 2.718, 2.718, "Float64 None ?? default")

// --- Section: Nested Some ---
let nested = Some(Some(42))
expectTrue(nested.isSome(), "nested Some outer isSome")
let inner = nested.getOrThrow()
expectTrue(inner.isSome(), "nested Some inner isSome")
expectEq(inner.getOrThrow(), 42, "nested Some inner value")

let deepNested = Some(Some(Some("deep")))
let mid = deepNested.getOrThrow()
let innermost = mid.getOrThrow()
expectEq(innermost.getOrThrow(), "deep", "triple nested Some value")

// --- Section: ?? chaining ---
let n1: ?Int64 = None
let n2: ?Int64 = None
let n3: ?Int64 = Some(77)
expectEq(n1 ?? n2 ?? n3 ?? 0, 77, "?? chain finds first Some")

let allNone1: ?Int64 = None
let allNone2: ?Int64 = None
let allNone3: ?Int64 = None
expectEq(allNone1 ?? allNone2 ?? allNone3 ?? -1, -1, "?? chain all None")

let first: ?Int64 = Some(10)
let second: ?Int64 = Some(20)
expectEq(first ?? second ?? 30, 10, "?? chain first wins")

// --- Section: getOrDefault with plain value ---
let gdNone: ?Int64 = None
expectEq(gdNone.getOrDefault(99), 99, "None getOrDefault plain value")
let gdSome: ?Int64 = Some(5)
expectEq(gdSome.getOrDefault(99), 5, "Some getOrDefault plain value")

// --- Section: getOrDefault with lambda ---
let gdLambda: ?Int64 = None
expectEq(gdLambda.getOrDefault({ => 7 * 8 }), 56, "None getOrDefault lambda")
let gdLambdaSome: ?Int64 = Some(1)
expectEq(gdLambdaSome.getOrDefault({ => 7 * 8 }), 1, "Some getOrDefault lambda")

// --- Section: if-let with Option ---
var ifLetVal = 0
if (let Some(v) <- oi) {
    ifLetVal = v
}
expectEq(ifLetVal, 42, "if-let unwraps Some Int64")

var ifLetStr = ""
if (let Some(v) <- os) {
    ifLetStr = v
}
expectEq(ifLetStr, "hello", "if-let unwraps Some String")

var ifLetElse = "untouched"
let emptyOpt: ?Int64 = None
if (let Some(v) <- emptyOpt) {
    ifLetElse = "found"
} else {
    ifLetElse = "not found"
}
expectEq(ifLetElse, "not found", "if-let else for None")

// --- Section: if-let with && condition ---
let optBig = Some(50)
var guardResult = ""
if (let Some(v) <- optBig && v > 10) {
    guardResult = "big: ${v}"
}
expectEq(guardResult, "big: 50", "if-let with && guard pass")

var guardFail = "untouched"
if (let Some(v) <- optBig && v > 100) {
    guardFail = "should not run"
}
expectEq(guardFail, "untouched", "if-let with && guard fail")

// --- Section: Option in match expression ---
func describeOpt(opt): String {
    return match (opt) {
        case Some(v) => "has: ${v}"
        case None => "empty"
    }
}
expectEq(describeOpt(Some(10)), "has: 10", "match Some")
expectEq(describeOpt(None), "empty", "match None")
expectEq(describeOpt(Some("abc")), "has: abc", "match Some string")

// --- Section: isSome/isNone on fresh values ---
expectTrue(Some(0).isSome(), "fresh Some(0) isSome")
expectFalse(Some(0).isNone(), "fresh Some(0) isNone")
expectTrue(None.isNone(), "fresh None isNone")
expectFalse(None.isSome(), "fresh None isSome")
expectTrue(Some("").isSome(), "fresh Some empty str isSome")
expectTrue(Some(false).isSome(), "fresh Some(false) isSome")

if (__test_failed) {
    println("FAIL: 86_option_advanced")
} else {
    println("PASS: 86_option_advanced")
}
