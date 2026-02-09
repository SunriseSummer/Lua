dofile("cangjie-tests/_testing.cj")

// Test: Option.getOrDefault accepts plain values (not just lambdas)

// --- Section: getOrDefault with plain Int64 ---
var a: ?Int64 = Some(42)
expectEq(a.getOrDefault(0), 42, "Some(42).getOrDefault(0)")

var b: ?Int64 = None
expectEq(b.getOrDefault(0), 0, "None.getOrDefault(0)")
expectEq(b.getOrDefault(-1), -1, "None.getOrDefault(-1)")
expectEq(b.getOrDefault(999), 999, "None.getOrDefault(999)")

// --- Section: getOrDefault with plain String ---
var c: ?String = Some("hello")
expectEq(c.getOrDefault("default"), "hello", "Some(hello).getOrDefault(default)")

var d: ?String = None
expectEq(d.getOrDefault("fallback"), "fallback", "None.getOrDefault(fallback)")
expectEq(d.getOrDefault(""), "", "None.getOrDefault(empty string)")

// --- Section: getOrDefault with plain Bool ---
var e: ?Bool = Some(true)
expectEq(e.getOrDefault(false), true, "Some(true).getOrDefault(false)")

var f: ?Bool = None
expectEq(f.getOrDefault(false), false, "None.getOrDefault(false)")
expectEq(f.getOrDefault(true), true, "None.getOrDefault(true)")

// --- Section: getOrDefault with plain Float64 ---
var g: ?Float64 = Some(3.14)
expectEq(g.getOrDefault(0.0), 3.14, "Some(3.14).getOrDefault(0.0)")

var h: ?Float64 = None
expectEq(h.getOrDefault(2.718), 2.718, "None.getOrDefault(2.718)")

// --- Section: getOrDefault with lambda still works ---
var i: ?Int64 = None
expectEq(i.getOrDefault({ => 5 * 10 }), 50, "None.getOrDefault(lambda)")

var j: ?Int64 = Some(7)
expectEq(j.getOrDefault({ => 5 * 10 }), 7, "Some(7).getOrDefault(lambda)")

// --- Section: chained option operations ---
var opt: ?Int64 = None
let result = opt ?? 100
expectEq(result, 100, "None ?? 100")

opt = Some(5)
let result2 = opt ?? 100
expectEq(result2, 5, "Some(5) ?? 100")

// --- Section: getOrDefault after reassignment ---
var mutable: ?String = Some("first")
expectEq(mutable.getOrDefault("x"), "first", "mutable Some getOrDefault")
mutable = None
expectEq(mutable.getOrDefault("second"), "second", "mutable None getOrDefault")
mutable = Some("third")
expectEq(mutable.getOrDefault("x"), "third", "mutable reassigned Some getOrDefault")

if (!__test_failed) {
    println("PASS: 82_option_getOrDefault_value")
}
