dofile("cangjie-tests/_testing.cj")

// Test: Lua coroutines (cooperative multitasking)
// Note: coroutine.* uses Lua's module call syntax with :

// -- Section: basic coroutine --
var steps = ""
let co = coroutine.create(func() {
  steps = steps + "1"
  coroutine.yield()
  steps = steps + "2"
  coroutine.yield()
  steps = steps + "3"
})

coroutine.resume(co)
expectEq(steps, "1", "coroutine step 1")
coroutine.resume(co)
expectEq(steps, "12", "coroutine step 2")
coroutine.resume(co)
expectEq(steps, "123", "coroutine step 3")

// -- Section: producer-consumer with coroutines --
func producer() {
  return coroutine.create(func() {
    var i = 1
    while (i <= 5) {
      coroutine.yield(i * 10)
      i = i + 1
    }
  })
}

let gen = producer()
var sum = 0
var values = ""
while (true) {
  let ok, val = coroutine.resume(gen)
  if (!ok || val == nil) {
    break
  }
  sum = sum + val
  values = values + tostring(val) + " "
}
expectEq(sum, 150, "coroutine producer sum")
expectEq(values, "10 20 30 40 50 ", "coroutine producer values")

if (!__test_failed) {
    println("PASS: ext-features/03_coroutines")
}
