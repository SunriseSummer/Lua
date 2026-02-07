// Shared test utility: Expect assertion functions
// Usage: dofile("cangjie-tests/_testing.cj")

var __test_failed = false

func expectEq(actual, expected, msg: String) {
    if (tostring(actual) != tostring(expected)) {
        println("FAIL: ${msg} - expected '${tostring(expected)}', got '${tostring(actual)}'")
        __test_failed = true
    }
}

func expectTrue(cond: Bool, msg: String) {
    if (!cond) {
        println("FAIL: ${msg} - expected true, got false")
        __test_failed = true
    }
}

func expectFalse(cond: Bool, msg: String) {
    if (cond) {
        println("FAIL: ${msg} - expected false, got true")
        __test_failed = true
    }
}

func expectNil(actual, msg: String) {
    if (actual != nil) {
        println("FAIL: ${msg} - expected nil, got '${tostring(actual)}'")
        __test_failed = true
    }
}
