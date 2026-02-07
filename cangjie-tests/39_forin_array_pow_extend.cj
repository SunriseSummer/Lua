dofile("cangjie-tests/_testing.cj")

// Test: for-in array iteration and extend method power operator
// Validates that arrays support for-in iteration and that the
// power operator (**) works correctly in extend method bodies.

// -- Section: Basic for-in array iteration --
let nums = [10, 20, 30]
var sum = 0
for (x in nums) {
    sum = sum + x
}
expectEq(sum, 60, "for-in array sum")

// -- Section: for-in with string array --
let names = ["Alice", "Bob", "Charlie"]
var concat = ""
for (name in names) {
    concat = concat .. name .. ","
}
expectEq(concat, "Alice,Bob,Charlie,", "for-in string array")

// -- Section: for-in with empty array --
let empty: Array<Int64> = []
var count = 0
for (x in empty) {
    count = count + 1
}
expectEq(count, 0, "for-in empty array")

// -- Section: for-in with single element --
let single = [42]
var singleVal = 0
for (x in single) {
    singleVal = x
}
expectEq(singleVal, 42, "for-in single element array")

// -- Section: Power operator in extend method --
interface Moveable {
    func move(dx: Float64, dy: Float64): Float64
}

struct Point2D {
    var x: Float64 = 0.0
    var y: Float64 = 0.0
}

extend Point2D <: Moveable {
    func move(dx: Float64, dy: Float64): Float64 {
        this.x = this.x + dx
        this.y = this.y + dy
        (dx ** 2 + dy ** 2) ** 0.5
    }
}

let pt = Point2D(1.0, 1.0)
let distance = pt.move(3.0, 4.0)
expectEq(distance, 5.0, "extend method with ** operator")
expectEq(pt.x, 4.0, "Point2D.x after move")
expectEq(pt.y, 5.0, "Point2D.y after move")

// -- Section: Power operator in regular method --
func hypotenuse(a: Float64, b: Float64): Float64 {
    (a ** 2 + b ** 2) ** 0.5
}
expectEq(hypotenuse(3.0, 4.0), 5.0, "hypotenuse standalone function")

// -- Section: for-in with object array --
struct SimpleObj {
    var value: Int64 = 0
}

let objs = [SimpleObj(1), SimpleObj(2), SimpleObj(3)]
var objSum = 0
for (obj in objs) {
    objSum = objSum + obj.value
}
expectEq(objSum, 6, "for-in object array")

if (!__test_failed) {
    println("PASS: 39_forin_array_pow_extend")
}
