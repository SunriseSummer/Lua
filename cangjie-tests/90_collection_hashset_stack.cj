dofile("cangjie-tests/_testing.cj")

// Test: HashSet and ArrayStack native collections

// --- HashSet basics ---
let set = HashSet()
expectTrue(set.isEmpty(), "hashset empty")
expectEq(set.size, 0, "hashset size 0")
expectTrue(set.add(1), "hashset add 1")
expectFalse(set.add(1), "hashset add duplicate")
set.add([2, 3, 3])
expectEq(set.size, 3, "hashset size after adds")
expectTrue(set.contains(2), "hashset contains 2")
expectFalse(set.contains(4), "hashset missing 4")

let more = HashSet([3, 4, 5])
expectTrue(set.contains([1, 2]), "hashset contains array")
expectFalse(set.contains([1, 6]), "hashset missing array element")

let subset = HashSet([1, 2])
expectTrue(subset.subsetOf(set), "subsetOf true")

set.retain(more)
expectEq(set.size, 1, "retain size")
expectTrue(set.contains(3), "retain keeps 3")

let a = HashSet([1, 2, 3])
let b = HashSet([3, 4])
let inter = a & b
expectEq(inter.size, 1, "intersection size")
expectTrue(inter.contains(3), "intersection contains 3")

let union = a | b
expectEq(union.size, 4, "union size")
expectTrue(union.contains(4), "union contains 4")

let diff = union - a
expectEq(diff.size, 1, "difference size")
expectTrue(diff.contains(4), "difference contains 4")
expectFalse(diff.contains(1), "difference missing 1")

expectTrue(a.remove(2), "hashset remove 2")
expectFalse(a.remove(8), "hashset remove missing")

let iter = union.iterator()
var iter_count = 0
while (let Some(v) <- iter()) {
    iter_count = iter_count + 1
}
expectEq(iter_count, union.size, "iterator count")

let union_arr = union.toArray()
expectEq(union_arr.size, union.size, "toArray size")

// --- ArrayStack basics ---
let stack = ArrayStack()
expectTrue(stack.isEmpty(), "stack empty")
expectEq(stack.size, 0, "stack size 0")
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

stack.clear()
expectTrue(stack.isEmpty(), "stack clear")

if (!__test_failed) {
    println("PASS: collection_hashset_stack")
}
