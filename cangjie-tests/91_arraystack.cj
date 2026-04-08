dofile("cangjie-tests/_testing.cj")

// Test: ArrayStack native collection

let stack = ArrayStack()
expectTrue(stack.isEmpty(), "stack empty")
expectEq(stack.size, 0, "stack size 0")
expectTrue(stack.capacity >= 8, "stack default capacity")
expectEq(stack.toString(), "[]", "stack empty tostring")
expectTrue(stack.peek().isNone(), "peek empty")
expectTrue(stack.remove().isNone(), "remove empty")

stack.add(10)
stack.add(20)
stack.add(30)
expectEq(stack.size, 3, "stack size 3")
expectEq(stack.peek().getOrDefault({=> 0}), 30, "peek top")

let popped = stack.remove().getOrDefault({=> 0})
expectEq(popped, 30, "remove top")
expectEq(stack.size, 2, "stack size after pop")
expectEq(stack.toString(), "[20, 10]", "stack tostring")

let siter = stack.iterator()
var seq = ""
while (let Some(v) <- siter()) {
    seq = seq + tostring(v)
}
expectEq(seq, "2010", "stack iterator order")

let stack_arr = stack.toArray()
expectEq(stack_arr.size, 2, "stack toArray size")
expectEq(stack_arr[0], 20, "stack toArray top")
expectEq(stack_arr[1], 10, "stack toArray next")

stack.reserve(5)
expectTrue(stack.capacity >= stack.size + 5, "stack reserve")
let cap_after = stack.capacity
stack.reserve(0)
expectEq(stack.capacity, cap_after, "stack reserve no-op")

stack.clear()
expectTrue(stack.isEmpty(), "stack clear")
expectEq(stack.toString(), "[]", "stack clear tostring")

if (!__test_failed) {
    println("PASS: arraystack")
}
