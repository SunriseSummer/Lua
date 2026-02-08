// Test: Lambda immediate invocation (IIFE) — { => expr }() and variants
dofile("cangjie-tests/_testing.cj")

// --- Basic IIFE: no params ---

let a = { => 42 }()
expectEq(a, 42, "basic IIFE no params returns int")

let b = { => "hello" }()
expectEq(b, "hello", "basic IIFE no params returns string")

let c = { => true }()
expectTrue(c, "basic IIFE no params returns true")

let d = { => false }()
expectFalse(d, "basic IIFE no params returns false")

// --- IIFE with params ---

let e = { x: Int64 => x * 2 }(21)
expectEq(e, 42, "IIFE with one typed param")

let f = { x: Int64, y: Int64 => x + y }(10, 20)
expectEq(f, 30, "IIFE with two typed params")

let g = { x, y => x * y }(6, 7)
expectEq(g, 42, "IIFE with untyped params")

// --- IIFE in expression contexts ---

let h = { => 10 }() + { => 20 }()
expectEq(h, 30, "IIFE in addition expression")

let i = { x: Int64 => x * 2 }(5) + { y: Int64 => y + 1 }(9)
expectEq(i, 20, "IIFE with params in addition")

// --- IIFE as function argument ---

func double(n: Int64): Int64 { return n * 2 }
let j = double({ => 21 }())
expectEq(j, 42, "IIFE as function argument")

// --- IIFE in array ---

let arr = [{ => 10 }(), { => 20 }(), { => 30 }()]
expectEq(arr[0], 10, "IIFE in array [0]")
expectEq(arr[1], 20, "IIFE in array [1]")
expectEq(arr[2], 30, "IIFE in array [2]")

// --- IIFE in if condition ---

var flag = false
if ({ => true }()) {
  flag = true
}
expectTrue(flag, "IIFE in if condition")

// --- IIFE returning lambda (chained call) ---

let k = { => { x: Int64 => x + 100 } }()(42)
expectEq(k, 142, "chained IIFE: lambda returning lambda")

// --- IIFE with multi-statement body ---

let l = { x: Int64 =>
  var result = x * 2
  result = result + 3
  return result
}(10)
expectEq(l, 23, "IIFE with multi-statement body")

// --- IIFE in let with type annotation ---

let m: Int64 = { => 99 }()
expectEq(m, 99, "IIFE in let with type annotation")

// --- IIFE with closure over outer variable ---

var outer = 100
let n = { => outer + 50 }()
expectEq(n, 150, "IIFE capturing outer variable")

// --- IIFE in var assignment ---

var o = { => 1 }()
expectEq(o, 1, "IIFE in var initial assignment")
o = { => 2 }()
expectEq(o, 2, "IIFE in var reassignment")

// --- IIFE nested in another IIFE ---

let p = { =>
  let inner = { => 42 }()
  return inner
}()
expectEq(p, 42, "nested IIFE")

// --- IIFE with string concatenation ---

let q = { => "hello" }() + " " + { => "world" }()
expectEq(q, "hello world", "IIFE in string concatenation")

if (!__test_failed) {
  println("PASS: all lambda IIFE tests passed")
}
