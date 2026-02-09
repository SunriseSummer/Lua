dofile("cangjie-tests/_testing.cj")

// Test: bound string methods and non-Option coalescing edge cases

let greeting = "  Hello  "
let trimFn = greeting.trim
expectEq(trimFn(), "Hello", "bound trim keeps original string")

let containsFn = "abc".contains
expectTrue(containsFn("b"), "bound contains finds substring")
expectFalse(containsFn("z"), "bound contains missing substring")

let upperFn = "abc".toAsciiUpper
expectEq(upperFn(), "ABC", "bound toAsciiUpper works")

let splitFn = "a,b,c".split
let parts = splitFn(",")
expectEq(parts.size, 3, "bound split size")
expectEq(parts[0], "a", "bound split first")
expectEq(parts[2], "c", "bound split last")

let arr = [1, 2, 3]
let coalesced = arr ?? [4]
expectEq(coalesced.size, 3, "?? on non-option table returns original")
expectEq(coalesced[0], 1, "?? preserves array contents")

if (!__test_failed) {
    println("PASS: 88_string_method_binding_boundary")
}
