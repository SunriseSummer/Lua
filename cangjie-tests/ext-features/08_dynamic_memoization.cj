dofile("cangjie-tests/_testing.cj")

// Extended feature: Dynamic type extension with closures and memoization
// Tests Lua dynamic features combined with Cangjie type system

// --- Section: Dynamic method dispatch table ---
var dispatch = {}
dispatch["greet"] = { name: String => "Hello, ${name}!" }
dispatch["farewell"] = { name: String => "Goodbye, ${name}!" }

let greetFn = dispatch["greet"]
let farewellFn = dispatch["farewell"]
expectEq(greetFn("Alice"), "Hello, Alice!", "dynamic dispatch greet")
expectEq(farewellFn("Bob"), "Goodbye, Bob!", "dynamic dispatch farewell")

// --- Section: Memoization via closure ---
func makeMemoized(fn) {
    var cache = {}
    return { key =>
        let cached = cache[key]
        if (cached != nil) {
            return cached
        }
        let result = fn(key)
        cache[key] = result
        return result
    }
}

var callCount: Int64 = 0
let expensive = makeMemoized({ x: Int64 =>
    callCount = callCount + 1
    return x * x + 1
})

expectEq(expensive(5), 26, "memo first call result")
expectEq(callCount, 1, "memo first call count")
expectEq(expensive(5), 26, "memo cached call result")
expectEq(callCount, 1, "memo cached call count (no extra call)")
expectEq(expensive(3), 10, "memo new key result")
expectEq(callCount, 2, "memo new key call count")

// --- Section: Dynamic property access via pcall ---
open class SafeBox {
    var value = nil
    func init(v) { this.value = v }
}

let box = SafeBox(42)
expectEq(box.value, 42, "safe box value")

let ok, err = pcall({ =>
    return box.nonexistent
})
expectTrue(ok, "accessing nonexistent property doesn't error")

// --- Section: Runtime type reflection ---
expectEq(type(42), "number", "type of integer")
expectEq(type(3.14), "number", "type of float")
expectEq(type("hello"), "String", "type of string")
expectEq(type(true), "boolean", "type of bool")
expectEq(type(nil), "nil", "type of nil")
expectEq(type({}), "table", "type of table")
expectEq(type({ => 1 }), "function", "type of lambda")

// --- Section: Varargs via table ---
func sumAll(nums) {
    var total: Int64 = 0
    let n = nums.size
    var i: Int64 = 0
    while (i < n) {
        total = total + nums[i]
        i = i + 1
    }
    return total
}

expectEq(sumAll([1, 2, 3, 4, 5]), 15, "sum array of 5")
expectEq(sumAll([]), 0, "sum empty array")
expectEq(sumAll([100]), 100, "sum single element")

if (!__test_failed) {
    println("PASS: 08_dynamic_memoization")
}
