// Signal simulation flow using interface default methods, operator overloading,
// type extensions, Option types, and compound assignment.
// This demonstrates a signal processing pipeline.

interface Slot {
    func compute(t: Float64): Float64
    operator func >>(that: Slot): Slot {
        that << this
        that
    }
    operator func <<(that: Slot): Slot { this }
}

extend Float64 <: Slot {
     func compute(t: Float64): Float64 {
        return this
    }
}

class Wave <: Slot {
     Wave(let freq: Float64, let phi: Float64) {}
     func compute(t: Float64): Float64 {
        return math.sin(2.0 * math.pi * freq * t + phi)
    }
}

class Mul <: Slot {
     Mul(let a: Slot, let b: Slot) {}
     func compute(t: Float64): Float64 {
        a.compute(t) * b.compute(t)
    }
}

class Integrator <: Slot {
    var input: ?Slot = None
    var sum = 0.0
    Integrator(let dt: Float64) {}
    func compute(t: Float64): Float64 {
        sum = sum + dt * input.getOrThrow().compute(t)
        return sum
    }
    operator func <<(that: Slot): Slot {
        input = Some(that)
        this
    }
}

let DT = 0.001
let left = 1.0 >> Integrator(DT)
let right = Wave(0.5 / Float64.GetPI(), 0.0)
let flow = Mul(left, right) >> Integrator(DT)

// Run 10 time steps
var results = Array(10, 0.0)
for (t in 0..10) {
    results[t] = flow.compute(Float64(t) * DT)
}

// Verify output: first value should be 0 (integral starts at 0)
var ok = true
if (results[0] != 0.0) { ok = false }

// Later values should be small positive numbers (integral accumulates)
for (i in 1..10) {
    if (results[i] < 0.0) { ok = false }  // should be >= 0
}

if (ok) {
    println("PASS: signal_simulation")
} else {
    println("FAIL: signal_simulation")
}
