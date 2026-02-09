dofile("cangjie-tests/_testing.cj")

// Test: Comprehensive edge cases for match, enum, option, and expression compositions

// --- Section: Match with boolean conditions ---
func classify(n: Int64): String {
    return match(n > 0) {
        case true => match(n > 100) {
            case true => "large positive"
            case false => "small positive"
        }
        case false => match(n == 0) {
            case true => "zero"
            case false => "negative"
        }
    }
}

expectEq(classify(500), "large positive", "classify 500")
expectEq(classify(50), "small positive", "classify 50")
expectEq(classify(0), "zero", "classify 0")
expectEq(classify(-5), "negative", "classify -5")

// --- Section: Enum with multiple parameters and nested match ---
enum Result {
    | Ok(Int64)
    | Err(String)
}

extend Result {
    func isOk(): Bool {
        return match(this) {
            case Ok(_) => true
            case _ => false
        }
    }
    func unwrapOr(default: Int64): Int64 {
        return match(this) {
            case Ok(v) => v
            case _ => default
        }
    }
    func map(f: (Int64) -> Int64): Result {
        return match(this) {
            case Ok(v) => Ok(f(v))
            case Err(e) => Err(e)
        }
    }
}

let ok1 = Ok(42)
expectTrue(ok1.isOk(), "Ok isOk")
expectEq(ok1.unwrapOr(0), 42, "Ok unwrapOr")

let err1 = Err("not found")
expectFalse(err1.isOk(), "Err isOk")
expectEq(err1.unwrapOr(-1), -1, "Err unwrapOr")

// Map transforms Ok values
let doubled = ok1.map({ v => v * 2 })
expectEq(doubled.unwrapOr(0), 84, "Ok map double")

// Map preserves Err
let errMapped = err1.map({ v => v * 2 })
expectFalse(errMapped.isOk(), "Err map preserves error")

// --- Section: Block expressions in various contexts ---
let blockVal = {
    let temp = 10
    temp * temp + 1
}
expectEq(blockVal, 101, "block expression value")

// Nested blocks
let nestedBlock = {
    let a = 5 + 5
    let b = a * 2
    a + b
}
expectEq(nestedBlock, 30, "nested block expression")

// --- Section: If expression as value ---
let ifVal = if (true) { 1 } else { 0 }
expectEq(ifVal, 1, "if expression true branch")

let ifVal2 = if (false) { 1 } else { 0 }
expectEq(ifVal2, 0, "if expression false branch")

// Nested if expressions
let nested = if (true) { if (false) { 1 } else { 2 } } else { 3 }
expectEq(nested, 2, "nested if expression")

// --- Section: String interpolation edge cases ---
let empty = ""
expectEq("${empty}", "", "interpolation of empty string")
expectEq("a${empty}b", "ab", "interpolation empty in middle")

let num = 42
expectEq("x${num}y", "x42y", "interpolation of number")
expectEq("${num + 1}", "43", "interpolation with arithmetic")

// --- Section: Multiple closure captures ---
var counter = 0
let inc = { => counter = counter + 1 }
let get = { => counter }

inc()
inc()
inc()
expectEq(get(), 3, "closure counter after 3 increments")

// --- Section: For loop with continue and break ---
var sum1 = 0
for (i in 0..10) {
    if (i % 2 == 0) {
        continue
    }
    sum1 = sum1 + i
}
expectEq(sum1, 25, "for loop with continue odd sum")

var sum2 = 0
for (i in 0..100) {
    if (i >= 5) {
        break
    }
    sum2 = sum2 + i
}
expectEq(sum2, 10, "for loop with break at 5")

// --- Section: Array operations ---
let arr = [10, 20, 30, 40, 50]
expectEq(arr.size, 5, "array size")
expectEq(arr[0], 10, "array first element")
expectEq(arr[4], 50, "array last element")

// Array slicing
let slice = arr[1..4]
expectEq(slice.size, 3, "slice size")
expectEq(slice[0], 20, "slice first")
expectEq(slice[2], 40, "slice last")

// Inclusive range slice
let sliceInc = arr[1..=3]
expectEq(sliceInc.size, 3, "inclusive slice size")
expectEq(sliceInc[0], 20, "inclusive slice first")
expectEq(sliceInc[2], 40, "inclusive slice last")

// --- Section: Tuple operations ---
let t = (1, "hello", true)
expectEq(t[0], 1, "tuple first")
expectEq(t[1], "hello", "tuple second")
expectTrue(t[2], "tuple third")

if (!__test_failed) {
    println("PASS: 83_comprehensive_features")
}
