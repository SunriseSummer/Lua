dofile("cangjie-tests/_testing.cj")

// Diagnosis: Option type error detection and edge cases

// --- Section: getOrDefault with None and various plain value types ---
expectNoError("getOrDefault None with Int64",
    "var o: ?Int64 = None; let r = o.getOrDefault(0)")

expectNoError("getOrDefault None with String",
    "var o: ?String = None; let r = o.getOrDefault(\"hello\")")

expectNoError("getOrDefault None with Bool",
    "var o: ?Bool = None; let r = o.getOrDefault(false)")

expectNoError("getOrDefault None with Float64",
    "var o: ?Float64 = None; let r = o.getOrDefault(0.0)")

// --- Section: getOrThrow on None should error ---
expectRuntimeError("getOrThrow on None",
    "var o: ?Int64 = None; o.getOrThrow()",
    "Option is None")

// --- Section: Option isSome/isNone ---
expectNoError("isSome on Some",
    "var o = Some(1); let r = o.isSome()")

expectNoError("isNone on None",
    "var o: ?Int64 = None; let r = o.isNone()")

// --- Section: Null coalescing operator ---
expectNoError("null coalescing with None",
    "var o: ?Int64 = None; let r = o ?? 42")

expectNoError("null coalescing with Some",
    "var o: ?Int64 = Some(5); let r = o ?? 42")

// --- Section: Return type mismatch for Option ---
expectRuntimeError("return Option without Some/None",
    "func parseInt(text: String): ?Int64 { return 1 }\nparseInt(\"1\")",
    "return type mismatch")

if (!__test_failed) {
    println("PASS: 15_option_errors")
}
