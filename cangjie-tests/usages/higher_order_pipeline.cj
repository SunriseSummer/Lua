// Usage: Higher-order function pipeline with function type annotations
// Demonstrates: function types in generics, lambda, IIFE, closures, structs
dofile("cangjie-tests/_testing.cj")

// --- Pipeline builder: chain transformations ---

struct Pipeline {
  var steps: Array<(Int64) -> Int64>
  
  init() {
    this.steps = []
  }

  func addStep(step: (Int64) -> Int64): Pipeline {
    let p = Pipeline()
    // Copy existing steps manually
    var i = 0
    while (i < this.steps.size) {
      p.steps[i] = this.steps[i]
      p.steps["__n"] = i + 1
      i = i + 1
    }
    // Add new step
    p.steps[i] = step
    p.steps["__n"] = i + 1
    return p
  }

  func run(input: Int64): Int64 {
    var result = input
    var i = 0
    while (i < this.steps.size) {
      result = this.steps[i](result)
      i = i + 1
    }
    return result
  }
}

let pipeline = Pipeline()
  .addStep({ x: Int64 => x + 10 })
  .addStep({ x: Int64 => x * 2 })
  .addStep({ x: Int64 => x - 5 })

expectEq(pipeline.run(5), 25, "pipeline: (5+10)*2-5 = 25")
expectEq(pipeline.run(0), 15, "pipeline: (0+10)*2-5 = 15")

// --- Compose utility ---

func compose(f: (Int64) -> Int64, g: (Int64) -> Int64): (Int64) -> Int64 {
  return { x => f(g(x)) }
}

let doubleIt: (Int64) -> Int64 = { x => x * 2 }
let addThree: (Int64) -> Int64 = { x => x + 3 }
let doubleThenAdd = compose(addThree, doubleIt)
let addThenDouble = compose(doubleIt, addThree)

expectEq(doubleThenAdd(5), 13, "compose: double then add3: 5*2+3=13")
expectEq(addThenDouble(5), 16, "compose: add3 then double: (5+3)*2=16")

// --- Accumulator factory with IIFE ---

func makeAccumulator(initial: Int64): (Int64) -> Int64 {
  var total = initial
  return { n: Int64 =>
    total = total + n
    return total
  }
}

let acc = makeAccumulator(0)
expectEq(acc(10), 10, "accumulator after +10")
expectEq(acc(20), 30, "accumulator after +20")
expectEq(acc(5), 35, "accumulator after +5")

// --- Immediate computation with IIFE ---

let result = { =>
  var sum = 0
  for (i in 1..=10) {
    sum = sum + i
  }
  return sum
}()
expectEq(result, 55, "IIFE computing sum 1..10")

// --- Strategy pattern with function types ---

func calculate(a: Int64, b: Int64, strategy: (Int64, Int64) -> Int64): Int64 {
  return strategy(a, b)
}

let strategies: Array<(Int64, Int64) -> Int64> = [
  { a, b => a + b },
  { a, b => a - b },
  { a, b => a * b }
]

expectEq(calculate(10, 3, strategies[0]), 13, "strategy add")
expectEq(calculate(10, 3, strategies[1]), 7, "strategy sub")
expectEq(calculate(10, 3, strategies[2]), 30, "strategy mul")

if (!__test_failed) {
  println("PASS: all higher-order pipeline usage tests passed")
}
