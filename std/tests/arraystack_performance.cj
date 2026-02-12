dofile("std/ArrayStack.cj")

let stack = ArrayStack()
let start = os.time()
for (i in 0..5000) {
    stack.add(i)
}
stack.reserve(500)
let cloned = stack.clone()
let iter = cloned.iterator()
var count = 0
while (let Some(_) <- iter()) {
    count = count + 1
}
var sum = 0
while (!stack.isEmpty()) {
    sum = sum + (stack.remove() ?? 0)
}
let elapsed = os.time() - start
println("ArrayStack performance: ${elapsed}s, sum=${sum}, count=${count}")
println("PASS: std/tests/arraystack_performance")
