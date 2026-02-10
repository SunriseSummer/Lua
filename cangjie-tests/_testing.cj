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

func expectType(value, expected: String, msg: String) {
    let actual = type(value)
    if (actual != expected) {
        println("FAIL: ${msg} - expected type '${expected}', got '${actual}'")
        __test_failed = true
    }
}

// -- Diagnosis helpers: error expectation utilities --

func expectLoadError(test_name: String, code: String, expected: String) {
    let result, err = load(code)
    if (result == nil) {
        let err_str = tostring(err)
        if (string.find(err_str, expected, 1, true) == nil) {
            println("FAIL: ${test_name} - expected '${expected}', got '${err_str}'")
            __test_failed = true
        }
    } else {
        println("FAIL: ${test_name} - expected a load error but code loaded successfully")
        __test_failed = true
    }
}

func expectRuntimeError(test_name: String, code: String, expected: String) {
    let chunk, err = load(code)
    if (chunk == nil) {
        println("FAIL: ${test_name} - code failed to load: ${tostring(err)}")
        __test_failed = true
        return ()
    }
    let ok, rerr = pcall(chunk)
    if (!ok) {
        let err_str = tostring(rerr)
        if (string.find(err_str, expected, 1, true) == nil) {
            println("FAIL: ${test_name} - expected '${expected}', got '${err_str}'")
            __test_failed = true
        }
    } else {
        println("FAIL: ${test_name} - expected a runtime error but code succeeded")
        __test_failed = true
    }
}

func expectNoError(test_name: String, code: String) {
    let result, err = load(code)
    if (result == nil) {
        println("FAIL: ${test_name} - expected success but got load error: ${tostring(err)}")
        __test_failed = true
    } else {
        let ok, rerr = pcall(result)
        if (!ok) {
            println("FAIL: ${test_name} - expected success but got runtime error: ${tostring(rerr)}")
            __test_failed = true
        }
    }
}
