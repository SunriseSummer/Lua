dofile("cangjie-tests/_testing.cj")

// Test: Primary constructor for struct and class

// Basic class with primary constructor
class Wave {
    Wave(let freq: Float64, var phi: Float64) {
    }
}

let w = Wave(440.0, 0.5)
expectEq(w.freq, 440.0, "w.freq")
expectEq(w.phi, 0.5, "w.phi")

// Modify var field (should succeed)
w.phi = 1.0
expectEq(w.phi, 1.0, "w.phi after set")

// Struct with primary constructor
struct Point3D {
    Point3D(let x: Int64, let y: Int64, let z: Int64) {
    }
    func toString(): String {
        return "(${x}, ${y}, ${z})"
    }
}

let p = Point3D(1, 2, 3)
expectEq(p.x, 1, "p.x")
expectEq(p.y, 2, "p.y")
expectEq(p.z, 3, "p.z")
expectEq(p.toString(), "(1, 2, 3)", "Point3D.toString()")

// Primary constructor with initialization logic in body
class Counter {
    Counter(var count: Int64, let step: Int64) {
        if (count < 0) {
            this.count = 0
        }
    }
    func increment() {
        this.count = this.count + this.step
    }
}

let c1 = Counter(5, 2)
expectEq(c1.count, 5, "c1.count")
c1.increment()
expectEq(c1.count, 7, "c1.count after increment")

// Primary constructor with negative count should be corrected to 0
let c2 = Counter(-3, 1)
expectEq(c2.count, 0, "c2.count (corrected)")

// Multiple instances with different values
let w1 = Wave(220.0, 0.0)
let w2 = Wave(880.0, 3.14)
expectEq(w1.freq, 220.0, "w1.freq")
expectEq(w2.freq, 880.0, "w2.freq")

// Existing init syntax should still work
class Traditional {
    var value: Int64
    init(v: Int64) {
        this.value = v * 10
    }
}

let t = Traditional(3)
expectEq(t.value, 30, "Traditional init")

if (!__test_failed) {
    println("PASS: 31_primary_constructor")
}
