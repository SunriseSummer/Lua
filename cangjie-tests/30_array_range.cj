// Test: Array range expression indexing

// Basic array
let arr = [10, 20, 30, 40, 50, 60, 70]

// Exclusive range: arr[0..3] -> elements at indices 0, 1, 2
let r1 = arr[0..3]
if (r1[0] != 10 || r1[1] != 20 || r1[2] != 30) {
    println("FAIL: arr[0..3] expected [10,20,30], got [" + tostring(r1[0]) + "," + tostring(r1[1]) + "," + tostring(r1[2]) + "]")
    return ()
}

// Inclusive range: arr[2..=4] -> elements at indices 2, 3, 4
let r2 = arr[2..=4]
if (r2[0] != 30 || r2[1] != 40 || r2[2] != 50) {
    println("FAIL: arr[2..=4] expected [30,40,50], got [" + tostring(r2[0]) + "," + tostring(r2[1]) + "," + tostring(r2[2]) + "]")
    return ()
}

// Range from start
let r3 = arr[0..=2]
if (r3[0] != 10 || r3[1] != 20 || r3[2] != 30) {
    println("FAIL: arr[0..=2] expected [10,20,30]")
    return ()
}

// Range at end
let r4 = arr[4..7]
if (r4[0] != 50 || r4[1] != 60 || r4[2] != 70) {
    println("FAIL: arr[4..7] expected [50,60,70]")
    return ()
}

// Single element range
let r5 = arr[3..=3]
if (r5[0] != 40) {
    println("FAIL: arr[3..=3] expected [40], got " + tostring(r5[0]))
    return ()
}

// Range assignment: exclusive
var arr2 = [0, 0, 0, 0, 0]
arr2[1..3] = [100, 200]
if (arr2[0] != 0 || arr2[1] != 100 || arr2[2] != 200 || arr2[3] != 0 || arr2[4] != 0) {
    println("FAIL: arr2[1..3] = [100,200], got [" + tostring(arr2[0]) + "," + tostring(arr2[1]) + "," + tostring(arr2[2]) + "," + tostring(arr2[3]) + "," + tostring(arr2[4]) + "]")
    return ()
}

// Range assignment: inclusive
var arr3 = [0, 0, 0, 0, 0, 0]
arr3[2..=4] = [10, 20, 30]
if (arr3[0] != 0 || arr3[1] != 0 || arr3[2] != 10 || arr3[3] != 20 || arr3[4] != 30 || arr3[5] != 0) {
    println("FAIL: arr3[2..=4] = [10,20,30]")
    return ()
}

// Verify sliced array has correct size
let r6 = arr[1..=5]
if (r6.__n != 5) {
    println("FAIL: arr[1..=5].__n expected 5, got " + tostring(r6.__n))
    return ()
}

println("PASS: 30_array_range")
