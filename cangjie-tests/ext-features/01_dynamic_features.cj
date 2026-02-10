dofile("cangjie-tests/_testing.cj")

// Test: Lua dynamic capabilities (extended Cangjie features)
// These features go beyond standard Cangjie syntax,
// leveraging Lua's dynamic nature for enhanced flexibility.

// -- Section: nil value (Lua's null) --
let z = nil
expectNil(z, "nil value")

// -- Section: multiple assignment --
let m, n = 100, 200
expectEq(m, 100, "multi-assign m")
expectEq(n, 200, "multi-assign n")

// -- Section: multiple return values --
func divmod(a: Int64, b: Int64) {
  return a / b, a % b
}
let q, r = divmod(17, 5)
expectEq(q, 3, "divmod quotient")
expectEq(r, 2, "divmod remainder")

// -- Section: dynamic typing --
var dyn = 42
expectEq(dyn, 42, "dyn as int")
dyn = "hello"
expectEq(dyn, "hello", "dyn as string")
dyn = true
expectTrue(dyn, "dyn as bool")

// -- Section: table as associative array --
let dict = {}
dict["name"] = "Cangjie"
dict["version"] = 1
dict[42] = "answer"
expectEq(dict["name"], "Cangjie", "dict name")
expectEq(dict["version"], 1, "dict version")
expectEq(dict[42], "answer", "dict numeric key")

// -- Section: # operator for raw table length --
let raw = {10, 20, 30}
expectEq(#raw, 3, "# operator")

// -- Section: ipairs iterator --
var ipairs_sum = 0
for (k, v in ipairs(raw)) {
  ipairs_sum = ipairs_sum + v
}
expectEq(ipairs_sum, 60, "ipairs sum")

// -- Section: pairs iterator --
var pairs_count = 0
for (k, v in pairs(dict)) {
  pairs_count = pairs_count + 1
}
expectEq(pairs_count, 3, "pairs count")

if (!__test_failed) {
    println("PASS: ext-features/01_dynamic_features")
}
