dofile("cangjie-tests/_testing.cj")

// Test: Compound assignment operators (+=, -=, *=, /=)

// Basic integer compound assignment
var a = 10
a += 5
expectEq(a, 15, "a += 5")

a -= 3
expectEq(a, 12, "a -= 3")

a *= 2
expectEq(a, 24, "a *= 2")

a /= 4
expectEq(a, 6.0, "a /= 4")

// Floating point compound assignment
var f = 1.0
f += 0.5
expectEq(f, 1.5, "f += 0.5")
f *= 2.0
expectEq(f, 3.0, "f *= 2.0")
f -= 0.5
expectEq(f, 2.5, "f -= 0.5")
f /= 2.0
expectEq(f, 1.25, "f /= 2.0")

// Compound assignment with complex expressions
var b = 10
b += 2 * 3
expectEq(b, 16, "b += 2 * 3")

// Compound assignment on struct fields (via method)
class Counter {
    var count = 0
    Counter() {}
    func increment(n: Int64) {
        count += n
    }
    func decrement(n: Int64) {
        count -= n
    }
    func getCount(): Int64 {
        return count
    }
}

let c = Counter()
c.increment(5)
expectEq(c.getCount(), 5, "counter after +5")
c.increment(3)
expectEq(c.getCount(), 8, "counter after +3")
c.decrement(2)
expectEq(c.getCount(), 6, "counter after -2")

// Compound assignment with negative values
var d = 100
d += -50
expectEq(d, 50, "d += -50")

// Multiple compound assignments in sequence
var e = 1
e += 1
e *= 3
e -= 1
expectEq(e, 5, "1+1=2, *3=6, -1=5")

if (!__test_failed) {
    println("PASS: 34_compound_assignment")
}
