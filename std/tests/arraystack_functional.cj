dofile("cangjie-tests/_testing.cj")
dofile("std/ArrayStack.cj")

let stack = ArrayStack()
expectTrue(stack.isEmpty(), "arraystack empty")
stack.add(1)
stack.add(2)
stack.add(3)
expectEq(stack.size, 3, "arraystack size after add")
expectEq(stack.remove() ?? -1, 3, "arraystack remove top")
expectEq(stack.size, 2, "arraystack size after remove")

let arr = stack.toArray()
expectEq(arr.size, 2, "arraystack toArray size")
expectEq(arr[0], 2, "arraystack toArray order")

let iter = stack.iterator()
var total = 0
while (let Some(v) <- iter()) {
    total = total + v
}
expectEq(total, 3, "arraystack iterator sum")

let clone = stack.clone()
clone.add(4)
expectEq(stack.size, 2, "arraystack clone independent")

let beforeCap = stack.capacity
stack.reserve(5)
expectTrue(stack.capacity - stack.size >= 5, "arraystack reserve additional")
expectTrue(stack.capacity >= beforeCap, "arraystack reserve grows")

let stackString = stack.toString()
expectTrue(stackString.contains("2"), "arraystack toString contains top")

stack.clear()
expectTrue(stack.isEmpty(), "arraystack clear")
expectTrue(stack.remove() == None, "arraystack remove empty")

if (!__test_failed) {
    println("PASS: std/tests/arraystack_functional")
}
