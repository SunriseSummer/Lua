dofile("cangjie-tests/_testing.cj")

// Usage: Iterator pattern with closures and Option type

// --- Build a range iterator using closures ---
func rangeIterator(start: Int64, end: Int64) {
    var current = start
    return { =>
        if (current < end) {
            let val = current
            current = current + 1
            return Some(val)
        }
        return None
    }
}

// Iterate and collect
let iter = rangeIterator(0, 5)
var sum = 0
var count = 0
while (let Some(v) <- iter()) {
    sum = sum + v
    count = count + 1
}
expectEq(sum, 10, "range iterator sum 0..5")
expectEq(count, 5, "range iterator count 0..5")

// --- Build a map function for arrays ---
func mapArray(arr: Array<Int64>, fn: (Int64) -> Int64): Array<Int64> {
    let result = Array<Int64>(arr.size, { i: Int64 => fn(arr[i]) })
    return result
}

let doubled = mapArray([1, 2, 3, 4, 5], { x => x * 2 })
expectEq(doubled[0], 2, "map doubled[0]")
expectEq(doubled[4], 10, "map doubled[4]")

// --- Build a filter count function ---
func countPositive(arr: Array<Int64>): Int64 {
    var count = 0
    for (x in arr) {
        if (x > 0) {
            count = count + 1
        }
    }
    return count
}

let posCount = countPositive([-3, -1, 0, 2, 5, -4, 8])
expectEq(posCount, 3, "count positive values")

// --- Sum positive values ---
func sumPositive(arr: Array<Int64>): Int64 {
    var total = 0
    for (x in arr) {
        if (x > 0) {
            total = total + x
        }
    }
    return total
}
expectEq(sumPositive([-3, -1, 0, 2, 5, -4, 8]), 15, "sum positive values")

// --- Build a reduce function ---
func reduce(arr: Array<Int64>, initial: Int64, fn: (Int64, Int64) -> Int64): Int64 {
    var acc = initial
    for (x in arr) {
        acc = fn(acc, x)
    }
    return acc
}

let total = reduce([1, 2, 3, 4, 5], 0, { acc, x => acc + x })
expectEq(total, 15, "reduce sum")

let product = reduce([1, 2, 3, 4, 5], 1, { acc, x => acc * x })
expectEq(product, 120, "reduce product")

let maxVal = reduce([3, 1, 4, 1, 5, 9, 2, 6], 0, { acc, x =>
    if (x > acc) { return x }
    return acc
})
expectEq(maxVal, 9, "reduce max")

// --- Compose two functions ---
func compose(f: (Int64) -> Int64, g: (Int64) -> Int64): (Int64) -> Int64 {
    return { x: Int64 => f(g(x)) }
}

let addOne = { x: Int64 => x + 1 }
let doubleIt = { x: Int64 => x * 2 }
let doubleAndAddOne = compose(addOne, doubleIt)
expectEq(doubleAndAddOne(5), 11, "compose(+1, *2)(5) = 11")

let addOneAndDouble = compose(doubleIt, addOne)
expectEq(addOneAndDouble(5), 12, "compose(*2, +1)(5) = 12")

if (!__test_failed) {
    println("PASS: iterator_functional")
}
