// Test compound assignment operators (+=, -=, *=, /=)

var a = 10
a += 5
var ok = true
if (a != 15) { ok = false }

a -= 3
if (a != 12) { ok = false }

a *= 2
if (a != 24) { ok = false }

a /= 4
if (a != 6) { ok = false }

// Test with floating point
var f = 1.0
f += 0.5
if (f != 1.5) { ok = false }
f *= 2.0
if (f != 3.0) { ok = false }

// Test compound assignment with complex expressions
var b = 10
b += 2 * 3
if (b != 16) { ok = false }

// Test compound assignment on struct fields
class Counter {
    var count = 0
    Counter() {}
    func increment(n: Int64) {
        count += n
    }
    func getCount(): Int64 {
        return count
    }
}

let c = Counter()
c.increment(5)
if (c.getCount() != 5) { ok = false }
c.increment(3)
if (c.getCount() != 8) { ok = false }

if (ok) {
    println("PASS: 34_compound_assignment")
} else {
    println("FAIL: 34_compound_assignment")
}
