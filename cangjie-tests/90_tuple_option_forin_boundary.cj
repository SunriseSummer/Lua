dofile("cangjie-tests/_testing.cj")

// Test: Tuple, Option, and for-in iterator boundary/edge cases combined

// --- Section: Tuple with Option elements ---
let someOne = Some(1)
let noneVal: ?Int64 = None
let someThree = Some(3)
let t1 = (someOne, noneVal, someThree)
expectTrue(t1[0].isSome(), "tuple opt elem 0 isSome")
expectTrue(t1[1].isNone(), "tuple opt elem 1 isNone")
expectTrue(t1[2].isSome(), "tuple opt elem 2 isSome")
expectEq(t1[0].getOrThrow(), 1, "tuple opt elem 0 value")
expectEq(t1[2].getOrThrow(), 3, "tuple opt elem 2 value")

// --- Section: Tuple size ---
let t2 = (10, 20, 30, 40, 50)
expectEq(t2.size, 5, "5-element tuple size")
expectEq(t2[0], 10, "5-tuple elem 0")
expectEq(t2[4], 50, "5-tuple elem 4")

// --- Section: Two-element tuple ---
let t3 = (42, 0)
expectEq(t3.size, 2, "two-element tuple size")
expectEq(t3[0], 42, "two-element tuple first")

// --- Section: Nested tuples ---
let inner1 = (1, 2)
let inner2 = (3, 4)
let t4 = (inner1, inner2)
expectEq(t4.size, 2, "nested tuple size")
expectEq(t4[0][0], 1, "nested tuple [0][0]")
expectEq(t4[0][1], 2, "nested tuple [0][1]")
expectEq(t4[1][0], 3, "nested tuple [1][0]")
expectEq(t4[1][1], 4, "nested tuple [1][1]")

// --- Section: Option ?? with complex expressions ---
let opt1: ?Int64 = Some(10)
let opt2: ?Int64 = None
let opt3: ?Int64 = Some(30)

let val1 = opt1 ?? 0
expectEq(val1, 10, "?? Some keeps value")

let val2 = opt2 ?? 99
expectEq(val2, 99, "?? None uses default")

// --- Section: Chained ?? ---
let chainResult = opt2 ?? opt1 ?? 0
// opt2 is None, so evaluate opt1 ?? 0 => opt1 is Some(10), so result = Some(10)
// but ?? unwraps Some, so chainResult should be 10 from opt1
expectEq(chainResult, 10, "chained ?? None then Some")

let allNone = opt2 ?? None ?? 42
expectEq(allNone, 42, "chained ?? all None until default")

// --- Section: for-in over string yields Rune ---
var runeCount: Int64 = 0
for (ch in "abc") {
    runeCount = runeCount + 1
}
expectEq(runeCount, 3, "for-in string char count")

// --- Section: for-in over UTF-8 string ---
var utfCount: Int64 = 0
for (ch in "你好世界") {
    utfCount = utfCount + 1
}
expectEq(utfCount, 4, "for-in UTF-8 string char count")

// --- Section: for-in over empty string ---
var emptyCount: Int64 = 0
for (ch in "") {
    emptyCount = emptyCount + 1
}
expectEq(emptyCount, 0, "for-in empty string")

// --- Section: for-in over array ---
let arr = [10, 20, 30, 40]
var arrSum: Int64 = 0
for (v in arr) {
    arrSum = arrSum + v
}
expectEq(arrSum, 100, "for-in array sum")

// --- Section: for-in over empty array ---
let emptyArr: Array<Int64> = []
var emptyArrSum: Int64 = 0
for (v in emptyArr) {
    emptyArrSum = emptyArrSum + 1
}
expectEq(emptyArrSum, 0, "for-in empty array")

// --- Section: Option with tuple value ---
let optTuple: ?(Int64, String) = Some((42, "hello"))
expectTrue(optTuple.isSome(), "option tuple isSome")
let unwrapped = optTuple.getOrThrow()
expectEq(unwrapped[0], 42, "option tuple [0]")
expectEq(unwrapped[1], "hello", "option tuple [1]")

// --- Section: getOrDefault with lambda ---
let noneOpt: ?Int64 = None
var sideEffect: Int64 = 0
let defVal = noneOpt.getOrDefault({ =>
    sideEffect = 1
    return 999
})
expectEq(defVal, 999, "getOrDefault lambda value")
expectEq(sideEffect, 1, "getOrDefault lambda side effect")

// Lambda should not be called for Some
let someOpt: ?Int64 = Some(42)
var noSideEffect: Int64 = 0
let someVal = someOpt.getOrDefault({ =>
    noSideEffect = 1
    return 999
})
expectEq(someVal, 42, "getOrDefault Some value")
expectEq(noSideEffect, 0, "getOrDefault Some no side effect")

if (!__test_failed) {
    println("PASS: 90_tuple_option_forin_boundary")
}
