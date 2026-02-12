dofile("cangjie-tests/_testing.cj")

// Perf: ArrayStack

let stack = ArrayStack()
let t0 = os.clock()
for (i in 0..5000) {
    stack.add(i)
}
let push_time = os.clock() - t0
println("arraystack push: ${push_time}")
expectEq(stack.size, 5000, "arraystack perf size")

let t1 = os.clock()
var sum = 0
for (i in 0..2500) {
    sum = sum + stack.remove().getOrDefault({=> 0})
}
let pop_time = os.clock() - t1
println("arraystack pop: ${pop_time}")
expectTrue(sum > 0, "arraystack perf pop sum")
expectTrue(stack.size < 5000, "arraystack perf pop size")

let t2 = os.clock()
stack.clear()
let clear_time = os.clock() - t2
println("arraystack clear: ${clear_time}")
expectTrue(stack.isEmpty(), "arraystack perf clear")

if (!__test_failed) {
    println("PASS: arraystack_perf")
}
