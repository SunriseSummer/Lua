// Test: Primary constructor for struct and class

// Basic class with primary constructor
class Wave {
    Wave(let freq: Float64, var phi: Float64) {
    }
}

let w = Wave(440.0, 0.5)
if (w.freq != 440.0) {
    println("FAIL: w.freq expected 440.0, got " + tostring(w.freq))
    return ()
}
if (w.phi != 0.5) {
    println("FAIL: w.phi expected 0.5, got " + tostring(w.phi))
    return ()
}

// Modify var field (should succeed)
w.phi = 1.0
if (w.phi != 1.0) {
    println("FAIL: w.phi after set expected 1.0, got " + tostring(w.phi))
    return ()
}

// Struct with primary constructor
struct Point3D {
    Point3D(let x: Int64, let y: Int64, let z: Int64) {
    }
    func toString(): String {
        return "(${x}, ${y}, ${z})"
    }
}

let p = Point3D(1, 2, 3)
if (p.x != 1 || p.y != 2 || p.z != 3) {
    println("FAIL: Point3D fields wrong")
    return ()
}
if (p.toString() != "(1, 2, 3)") {
    println("FAIL: Point3D.toString() expected '(1, 2, 3)', got '" + p.toString() + "'")
    return ()
}

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
if (c1.count != 5) {
    println("FAIL: c1.count expected 5, got " + tostring(c1.count))
    return ()
}
c1.increment()
if (c1.count != 7) {
    println("FAIL: c1.count after increment expected 7, got " + tostring(c1.count))
    return ()
}

// Primary constructor with negative count should be corrected to 0
let c2 = Counter(-3, 1)
if (c2.count != 0) {
    println("FAIL: c2.count expected 0 (corrected), got " + tostring(c2.count))
    return ()
}

// Multiple instances with different values
let w1 = Wave(220.0, 0.0)
let w2 = Wave(880.0, 3.14)
if (w1.freq != 220.0 || w2.freq != 880.0) {
    println("FAIL: multiple instances have wrong values")
    return ()
}

// Existing init syntax should still work
class Traditional {
    var value: Int64
    init(v: Int64) {
        this.value = v * 10
    }
}

let t = Traditional(3)
if (t.value != 30) {
    println("FAIL: Traditional init expected 30, got " + tostring(t.value))
    return ()
}

println("PASS: 31_primary_constructor")
