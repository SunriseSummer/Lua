dofile("cangjie-tests/_testing.cj")

// Test: Lambda closures capturing and mutating variables

// -- Section: Multiple lambdas sharing same mutable variable --
var shared = 0
let incr = { => shared = shared + 1 }
let decr = { => shared = shared - 1 }
let read = { => shared }
incr()
incr()
incr()
expectEq(read(), 3, "shared var after 3 incr")
decr()
expectEq(read(), 2, "shared var after decr")

// -- Section: Lambda modifying captured variable, read by another --
var state = "init"
let setState = { s => state = s }
let getState = { => state }
expectEq(getState(), "init", "initial state")
setState("running")
expectEq(getState(), "running", "state after set")
setState("done")
expectEq(getState(), "done", "state after second set")

// -- Section: Counter pattern with increment/decrement/read --
func makeCounter(start: Int64) {
    var count = start
    let inc = { => count = count + 1; return count }
    let dec = { => count = count - 1; return count }
    let get = { => count }
    return (inc, dec, get)
}
let ctr = makeCounter(10)
let cInc = ctr[0]
let cDec = ctr[1]
let cGet = ctr[2]
expectEq(cGet(), 10, "counter initial")
expectEq(cInc(), 11, "counter inc")
expectEq(cInc(), 12, "counter inc again")
expectEq(cDec(), 11, "counter dec")
expectEq(cGet(), 11, "counter final")

// -- Section: Closure over loop variable --
var fns = []
var fnIdx = 0
for (i in 0..3) {
    let captured = i
    fns[fnIdx] = { => captured }
    fnIdx = fnIdx + 1
}
expectEq(fns[0](), 0, "loop closure 0")
expectEq(fns[1](), 1, "loop closure 1")
expectEq(fns[2](), 2, "loop closure 2")

// -- Section: Lambda returning lambda capturing outer state --
func makeAccumulator() {
    var total = 0
    return { n =>
        total = total + n
        return total
    }
}
let acc = makeAccumulator()
expectEq(acc(5), 5, "accumulator 5")
expectEq(acc(3), 8, "accumulator +3")
expectEq(acc(2), 10, "accumulator +2")

// -- Section: Nested closure chain --
func outer() {
    var x = 1
    let middle = { =>
        x = x + 10
        let inner = { => x * 2 }
        return inner()
    }
    return middle
}
let mid = outer()
expectEq(mid(), 22, "nested closure chain (1+10)*2")

// -- Section: Two independent closures from same factory --
let acc1 = makeAccumulator()
let acc2 = makeAccumulator()
acc1(10)
acc1(20)
acc2(5)
expectEq(acc1(0), 30, "acc1 independent")
expectEq(acc2(0), 5, "acc2 independent")

if (!__test_failed) {
    println("PASS: 70_closure_mutation")
}
