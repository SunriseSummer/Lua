// Test: Complex type annotations — function types in generics, nested generics
dofile("cangjie-tests/_testing.cj")

// --- Function type annotation in generic: Array<(T) -> T> ---

let fns: Array<(Int64) -> Int64> = [{ x => x + 1 }, { x => x * 2 }]
expectEq(fns[0](5), 6, "Array<(Int64)->Int64> single param fn call [0]")
expectEq(fns[1](5), 10, "Array<(Int64)->Int64> single param fn call [1]")

// --- Multi-param function type in generic ---

let ops: Array<(Int64, Int64) -> Int64> = [
  { a, b => a + b },
  { a, b => a * b },
  { a, b => a - b }
]
expectEq(ops[0](3, 4), 7, "Array<(Int64,Int64)->Int64> add")
expectEq(ops[1](3, 4), 12, "Array<(Int64,Int64)->Int64> mul")
expectEq(ops[2](3, 4), -1, "Array<(Int64,Int64)->Int64> sub")

// --- Simple function type annotation ---

let fn1: (Int64) -> Int64 = { x => x * 10 }
expectEq(fn1(3), 30, "simple function type (Int64)->Int64")

let fn2: (Int64, Int64) -> Int64 = { a, b => a + b }
expectEq(fn2(10, 20), 30, "simple function type (Int64,Int64)->Int64")

// --- Nested generic types ---

var nested: Array<Array<Int64>> = [[10, 20], [30, 40]]
expectEq(nested[0][0], 10, "Array<Array<Int64>> [0][0]")
expectEq(nested[0][1], 20, "Array<Array<Int64>> [0][1]")
expectEq(nested[1][0], 30, "Array<Array<Int64>> [1][0]")
expectEq(nested[1][1], 40, "Array<Array<Int64>> [1][1]")

// --- Deeply nested generic types ---

let deep: Array<Array<Array<Int64>>> = [[[1, 2], [3]], [[4, 5, 6]]]
expectEq(deep[0][0][0], 1, "Array<Array<Array<Int64>>> [0][0][0]")
expectEq(deep[0][0][1], 2, "Array<Array<Array<Int64>>> [0][0][1]")
expectEq(deep[0][1][0], 3, "Array<Array<Array<Int64>>> [0][1][0]")
expectEq(deep[1][0][2], 6, "Array<Array<Array<Int64>>> [1][0][2]")

// --- Function type as function parameter ---

func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 {
  return fn(a, b)
}
expectEq(apply({ x, y => x + y }, 5, 6), 11, "func param with function type")
expectEq(apply({ x, y => x * y }, 5, 6), 30, "func param with function type mul")

// --- Function type as return type ---

func makeAdder(n: Int64): (Int64) -> Int64 {
  return { x => x + n }
}
let add10 = makeAdder(10)
expectEq(add10(5), 15, "function returning function type")
expectEq(add10(0), 10, "function returning function type zero")

// --- Option with generic type ---

let opt: ?Array<Int64> = [1, 2, 3]
expectEq(opt[0], 1, "?Array<Int64> access")

let optNil: ?Array<Int64> = nil
expectNil(optNil, "?Array<Int64> nil")

// --- Function type in struct member ---

struct Transformer {
  var transform: (Int64) -> Int64
  init(transform: (Int64) -> Int64) {
    this.transform = transform
  }
  func apply(val: Int64): Int64 {
    return this.transform(val)
  }
}
let t = Transformer({ x => x * x })
expectEq(t.apply(5), 25, "struct with function type field")

// --- var with function type ---

var mutableFn: (Int64) -> Int64 = { x => x + 1 }
expectEq(mutableFn(10), 11, "var with function type initial")
mutableFn = { x => x * 3 }
expectEq(mutableFn(10), 30, "var with function type reassigned")

if (!__test_failed) {
  println("PASS: all complex type annotation tests passed")
}
