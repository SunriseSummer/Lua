// Test multi-dimensional array range/slice indexing

// Create a 2D array: 5 rows x 128 cols, initialized to 0
let states = Array(5, { i: Int64 => Array(128, 0)})

// Range assignment on multi-dimensional array
states[0][45..58] = [1, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]

// Verify assigned values
var ok = true
if (states[0][45] != 1) { ok = false }
if (states[0][46] != 2) { ok = false }
if (states[0][47] != 0) { ok = false }
if (states[0][48] != 3) { ok = false }
if (states[0][57] != 3) { ok = false }

// Verify unchanged elements
if (states[0][44] != 0) { ok = false }
if (states[0][58] != 0) { ok = false }
if (states[1][45] != 0) { ok = false }

// Range read on multi-dimensional array
let a = Array(3, { i: Int64 => Array(5, { j: Int64 => i * 10 + j })})
let sl = a[1][1..4]
if (sl[0] != 11) { ok = false }
if (sl[1] != 12) { ok = false }
if (sl[2] != 13) { ok = false }

// Inclusive range on multi-dimensional array
let sl2 = a[2][0..=2]
if (sl2[0] != 20) { ok = false }
if (sl2[1] != 21) { ok = false }
if (sl2[2] != 22) { ok = false }

if (ok) {
    println("PASS: 32_multidim_array_slice")
} else {
    println("FAIL: 32_multidim_array_slice")
}
