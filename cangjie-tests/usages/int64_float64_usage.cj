dofile("cangjie-tests/_testing.cj")

// Test: Comprehensive Int64/Float64 arithmetic and conversion usage

// --- Section: Integer arithmetic chain ---
func factorial(n: Int64): Int64 {
    if (n <= 1) { return 1 }
    return n * factorial(n - 1)
}
expectEq(factorial(0), 1, "0!")
expectEq(factorial(1), 1, "1!")
expectEq(factorial(5), 120, "5!")
expectEq(factorial(10), 3628800, "10!")

// --- Section: Float64 precision computation ---
func approxPi(terms: Int64): Float64 {
    var sum = 0.0
    for (i in 0..terms) {
        let sign = (-1) ** i
        sum = sum + Float64(sign) / Float64(2 * i + 1)
    }
    return sum * 4.0
}
let pi = approxPi(1000)
// Pi approx should be close to 3.14
expectTrue(pi > 3.14 && pi < 3.15, "pi approximation in range")

// --- Section: Mixed-type expression chains ---
let intVal = 10
let floatVal = 2.5
let result = Float64(intVal) * floatVal
expectEq(result, 25.0, "explicit conversion in expression")

// Integer division chain
let a = 100
let b = a / 7        // 14
let c = b / 3        // 4
expectEq(b, 14, "100/7 = 14")
expectEq(c, 4, "14/3 = 4")

// --- Section: Power and division combined ---
let base = 2
let exp = 10
let power_result = base ** exp
expectEq(power_result, 1024, "2^10")
let div_result = power_result / 100
expectEq(div_result, 10, "1024/100 = 10")

// --- Section: Numeric type in data structures ---
let intArray: Array<Int64> = [1, 2, 3, 4, 5]
var intSum = 0
for (v in intArray) {
    intSum = intSum + v
}
expectEq(intSum, 15, "int array sum")

let floatArray: Array<Float64> = [1.5, 2.5, 3.5]
var floatSum = 0.0
for (v in floatArray) {
    floatSum = floatSum + v
}
expectEq(floatSum, 7.5, "float array sum")

// --- Section: Int/Float average computation ---
func intAverage(arr: Array<Int64>): Float64 {
    var sum = 0
    for (v in arr) { sum = sum + v }
    return Float64(sum) / Float64(arr.size)
}
let avg = intAverage([10, 20, 30])
expectEq(avg, 20.0, "average of [10,20,30]")

let avg2 = intAverage([1, 2, 3, 4])
expectEq(avg2, 2.5, "average of [1,2,3,4]")

// --- Section: Euclidean distance (mixed types) ---
func distance(x1: Int64, y1: Int64, x2: Int64, y2: Int64): Float64 {
    let dx = x2 - x1
    let dy = y2 - y1
    return (Float64(dx * dx + dy * dy)) ** 0.5
}
expectEq(distance(0, 0, 3, 4), 5.0, "distance (0,0)-(3,4) = 5")
expectEq(distance(0, 0, 0, 0), 0.0, "distance same point = 0")

// --- Section: GCD using integer operations ---
func gcd(a: Int64, b: Int64): Int64 {
    var x = a
    var y = b
    if (x < 0) { x = -x }
    if (y < 0) { y = -y }
    while (y != 0) {
        let temp = y
        y = x % y
        x = temp
    }
    return x
}
expectEq(gcd(12, 8), 4, "gcd(12,8)")
expectEq(gcd(100, 75), 25, "gcd(100,75)")
expectEq(gcd(7, 13), 1, "gcd(7,13) coprime")
expectEq(gcd(-12, 8), 4, "gcd(-12,8)")

// --- Section: String/Int64/Float64 conversion pipeline ---
let numStr = "42"
let num = Int64(numStr)
let doubled = num * 2
let asFloat = Float64(doubled)
let halved = asFloat / 3.0
let backToStr = String(halved)
expectEq(backToStr, "28.0", "conversion pipeline result")

if (!__test_failed) {
    println("PASS: int64_float64_usage")
}
