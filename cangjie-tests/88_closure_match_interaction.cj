dofile("cangjie-tests/_testing.cj")

// Test: Closures interacting with match, class methods, and mutable state

// --- Section: Closure captures variable modified in match ---
var counter: Int64 = 0

func applyMatch(x: Int64): Int64 {
    match (x) {
        case 1 => counter = counter + 1
        case 2 => counter = counter + 10
        case 3 => counter = counter + 100
        case _ => counter = counter + 0
    }
    return counter
}

applyMatch(1)
expectEq(counter, 1, "closure match counter 1")
applyMatch(2)
expectEq(counter, 11, "closure match counter 2")
applyMatch(3)
expectEq(counter, 111, "closure match counter 3")

// --- Section: Closure factory producing different behaviors via match ---
func makeProcessor(kind: String): (Int64) -> Int64 {
    let double_fn = { x: Int64 => x * 2 }
    let square_fn = { x: Int64 => x * x }
    let id_fn = { x: Int64 => x }
    return match (kind) {
        case "double" => double_fn
        case "square" => square_fn
        case _ => id_fn
    }
}

let doubler = makeProcessor("double")
let squarer = makeProcessor("square")
let identity = makeProcessor("other")

expectEq(doubler(5), 10, "closure factory double")
expectEq(squarer(5), 25, "closure factory square")
expectEq(identity(5), 5, "closure factory identity")

// --- Section: Closure inside class method capturing this ---
open class Accumulator {
    var total: Int64 = 0

    func makeAdder(): (Int64) -> Int64 {
        return { n: Int64 =>
            this.total = this.total + n
            return this.total
        }
    }
}

let acc = Accumulator()
let adder = acc.makeAdder()
expectEq(adder(5), 5, "closure this capture add 5")
expectEq(adder(3), 8, "closure this capture add 3")
expectEq(acc.total, 8, "closure this capture total")

// --- Section: Multiple closures sharing mutable state ---
func makeCounterPair() {
    var shared: Int64 = 0
    let inc = { n: Int64 =>
        shared = shared + n
        return shared
    }
    let dec = { n: Int64 =>
        shared = shared - n
        return shared
    }
    return (inc, dec)
}

let pair = makeCounterPair()
let inc = pair[0]
let dec = pair[1]
expectEq(inc(10), 10, "shared state inc 10")
expectEq(inc(5), 15, "shared state inc 5")
expectEq(dec(3), 12, "shared state dec 3")

// --- Section: Closure in loop capturing iteration variable ---
let mkClosure = { i: Int64 => return { => i * i } }
var closures = Array(5, mkClosure)
expectEq(closures[0](), 0, "loop closure 0*0")
expectEq(closures[1](), 1, "loop closure 1*1")
expectEq(closures[2](), 4, "loop closure 2*2")
expectEq(closures[3](), 9, "loop closure 3*3")
expectEq(closures[4](), 16, "loop closure 4*4")

// --- Section: Closure returned from match expression ---
func makeOp(op: String): (Int64, Int64) -> Int64 {
    let add_fn = { a: Int64, b: Int64 => a + b }
    let mul_fn = { a: Int64, b: Int64 => a * b }
    let def_fn = { a: Int64, b: Int64 => 0 }
    return match (op) {
        case "add" => add_fn
        case "mul" => mul_fn
        case _ => def_fn
    }
}

let addOp = makeOp("add")
let mulOp = makeOp("mul")
let defOp = makeOp("unknown")

expectEq(addOp(3, 4), 7, "match closure add")
expectEq(mulOp(3, 4), 12, "match closure mul")
expectEq(defOp(3, 4), 0, "match closure default")

if (!__test_failed) {
    println("PASS: 88_closure_match_interaction")
}
