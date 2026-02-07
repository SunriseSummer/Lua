dofile("cangjie-tests/_testing.cj")

// Test: Multi-dimensional array range/slice indexing

// Create a 2D array: 5 rows x 128 cols, initialized to 0
let states = Array(5, { i: Int64 => Array(128, 0)})

// Range assignment on multi-dimensional array
states[0][45..58] = [1, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]

// Verify assigned values
expectEq(states[0][45], 1, "states[0][45]")
expectEq(states[0][46], 2, "states[0][46]")
expectEq(states[0][47], 0, "states[0][47]")
expectEq(states[0][48], 3, "states[0][48]")
expectEq(states[0][57], 3, "states[0][57]")

// Verify unchanged elements
expectEq(states[0][44], 0, "states[0][44] unchanged")
expectEq(states[0][58], 0, "states[0][58] unchanged")
expectEq(states[1][45], 0, "states[1][45] unchanged")

// Range read on multi-dimensional array
let a = Array(3, { i: Int64 => Array(5, { j: Int64 => i * 10 + j })})
let sl = a[1][1..4]
expectEq(sl[0], 11, "a[1][1..4][0]")
expectEq(sl[1], 12, "a[1][1..4][1]")
expectEq(sl[2], 13, "a[1][1..4][2]")

// Inclusive range on multi-dimensional array
let sl2 = a[2][0..=2]
expectEq(sl2[0], 20, "a[2][0..=2][0]")
expectEq(sl2[1], 21, "a[2][0..=2][1]")
expectEq(sl2[2], 22, "a[2][0..=2][2]")

// Nested array literal with range read
let b = [[10, 20, 30, 40, 50], [60, 70, 80, 90, 100]]
let sl3 = b[1][1..4]
expectEq(sl3[0], 70, "b[1][1..4][0]")
expectEq(sl3[1], 80, "b[1][1..4][1]")
expectEq(sl3[2], 90, "b[1][1..4][2]")

// Range assignment on nested array
let c = [[0, 0, 0, 0], [0, 0, 0, 0]]
c[0][1..3] = [77, 88]
expectEq(c[0][0], 0, "c[0][0] unchanged")
expectEq(c[0][1], 77, "c[0][1] assigned")
expectEq(c[0][2], 88, "c[0][2] assigned")
expectEq(c[0][3], 0, "c[0][3] unchanged")
expectEq(c[1][1], 0, "c[1][1] unchanged")

if (!__test_failed) {
    println("PASS: 32_multidim_array_slice")
}
