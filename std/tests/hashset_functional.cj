dofile("cangjie-tests/_testing.cj")
dofile("std/HashSet.cj")

let set = HashSet()
expectTrue(set.isEmpty(), "hashset empty")
expectTrue(set.add(1), "hashset add 1")
expectFalse(set.add(1), "hashset add duplicate")
set.add(2)
set.add(3)
expectEq(set.size, 3, "hashset size")
expectTrue(set.contains(2), "hashset contains 2")
expectTrue(set.remove(1), "hashset remove 1")
expectFalse(set.contains(1), "hashset removed 1")

set.add(4)
set.removeIf({ v => v % 2 == 0 })
expectFalse(set.contains(2), "hashset removeIf removed 2")
expectFalse(set.contains(4), "hashset removeIf removed 4")

let subset = HashSet()
subset.add(3)
expectTrue(subset.subsetOf(set), "hashset subsetOf")
set.retain(subset)
expectEq(set.size, 1, "hashset retain size")
expectTrue(set.contains(3), "hashset retain keeps 3")

let arr = set.toArray()
expectEq(arr.size, 1, "hashset toArray size")
expectEq(arr[0], 3, "hashset toArray value")

let iter = set.iterator()
var total = 0
while (let Some(v) <- iter()) {
    total = total + v
}
expectEq(total, 3, "hashset iterator sum")

let cloned = set.clone()
cloned.add(5)
expectFalse(set.contains(5), "hashset clone independent")

let beforeCap = set.capacity
set.reserve(4)
expectTrue(set.capacity - set.size >= 4, "hashset reserve additional")
expectTrue(set.capacity >= beforeCap, "hashset reserve grows")

let setString = set.toString()
expectTrue(setString.contains("3"), "hashset toString contains 3")

set.clear()
expectTrue(set.isEmpty(), "hashset clear")

if (!__test_failed) {
    println("PASS: std/tests/hashset_functional")
}
