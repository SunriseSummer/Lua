dofile("cangjie-tests/_testing.cj")

// Test: Option getOrDefault lazy evaluation and bound method behavior

var defaultCalls = 0
func defaultValue(): Int64 {
    defaultCalls = defaultCalls + 1
    return 99
}

let someVal: ?Int64 = Some(5)
let resultSome = someVal.getOrDefault({ => defaultValue() })
expectEq(resultSome, 5, "getOrDefault returns Some without calling default")
expectEq(defaultCalls, 0, "getOrDefault does not call default for Some")

let boundDefault = someVal.getOrDefault
expectEq(boundDefault(123), 5, "bound getOrDefault keeps Some value")
expectEq(defaultCalls, 0, "bound getOrDefault stays lazy for Some")

let noneVal: ?Int64 = None
let resultNone = noneVal.getOrDefault({ => defaultValue() })
expectEq(resultNone, 99, "getOrDefault uses default for None")
expectEq(defaultCalls, 1, "getOrDefault default invoked once for None")

if (__test_failed) {
    println("FAIL: 87_option_lazy_default")
} else {
    println("PASS: 87_option_lazy_default")
}
