// Basic syntax coverage for Cangjie-style frontend

func add(a: Int, b: Int): Int {
  return a + b
}

let total: Int = add(2, 3)
if (total != 5) {
  error("function add failed")
}

/* collection literal */
let nums: Array<Int> = [1, 2, 3]
if (nums[2] != 2) {
  error("array literal failed")
}

var sum: Int = 0
for (i in 1..=3) {
  sum = sum + nums[i]
}
if (sum != 6) {
  error("for range failed")
}

var sum2: Int = 0
for (item in nums) {
  sum2 = sum2 + item
}
if (sum2 != 6) {
  error("for-in failed")
}

var idx: Int = 1
var accum: Int = 0
while (idx <= 3) {
  accum = accum + nums[idx]
  idx = idx + 1
}

var status: String = ""
if (accum > 10) {
  status = "big"
} else if (accum == 6) {
  status = "ok"
} else {
  status = "small"
}
if (status != "ok") {
  error("else-if failed")
}

if (!(false || false) && true) {
  // ok
} else {
  error("logical operators failed")
}

let nothing: Any = null
if (nothing != null) {
  error("null handling failed")
}
