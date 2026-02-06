// Extended features: Lua coroutines
// Coroutines provide cooperative multitasking beyond standard Cangjie.
// Note: coroutine.* uses Lua's module call syntax with :

// Basic coroutine
let co = coroutine.create(func() {
  println("step 1")
  coroutine.yield()
  println("step 2")
  coroutine.yield()
  println("step 3")
})

coroutine.resume(co)  // step 1
coroutine.resume(co)  // step 2
coroutine.resume(co)  // step 3

// Producer-consumer pattern with coroutines
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
while (true) {
  let ok, val = coroutine.resume(gen)
  if (not ok or val == nil) {
    break
  }
  sum = sum + val
  print("${val} ")
}
println()
println("sum = ${sum}")  // 150

println("PASS: ext-features/03_coroutines")
