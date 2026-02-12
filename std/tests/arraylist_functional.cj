dofile("cangjie-tests/_testing.cj")
dofile("std/ArrayList.cj")

let list = ArrayList()
expectTrue(list.isEmpty(), "arraylist empty")
list.add(3)
list.add(1)
list.add(2)
expectEq(list.size, 3, "arraylist size after add")
expectTrue(list.capacity >= list.size, "arraylist capacity")
expectEq(list.get(1) ?? -1, 1, "arraylist get index 1")
expectTrue(list.contains(2), "arraylist contains 2")
expectTrue(list.get(-1) == None, "arraylist get negative")
expectTrue(list.get(99) == None, "arraylist get out of range")

expectEq(list.remove(1) ?? -1, 1, "arraylist remove index 1")
expectEq(list.size, 2, "arraylist size after remove")
expectTrue(list.remove(99) == None, "arraylist remove out of range")
list.add(4)
list.add(5)
list.removeIf({ v => v % 2 == 0 })
expectFalse(list.contains(4), "arraylist removeIf removes 4")
expectEq(list.size, 2, "arraylist size after removeIf")

let cloned = list.clone()
cloned.add(7)
expectEq(list.size, 2, "arraylist clone independent")
cloned.reverse()
expectEq(cloned.get(0) ?? -1, 7, "arraylist reverse")

let sliceSource = ArrayList()
for (i in 0..5) {
    sliceSource.add(i)
}
let slice = sliceSource.slice(1, 3)
expectEq(slice.size, 3, "arraylist slice size")
expectEq(slice.get(0) ?? -1, 1, "arraylist slice first")

let iter = sliceSource.iterator()
var sum = 0
while (let Some(v) <- iter()) {
    sum = sum + v
}
expectEq(sum, 10, "arraylist iterator sum")

let sortable = ArrayList()
sortable.add(3)
sortable.add(1)
sortable.add(2)
sortable.sortBy({ a, b =>
    if (a < b) { return Ordering.LT }
    if (a > b) { return Ordering.GT }
    return Ordering.EQ
})
let sortedArr = sortable.toArray()
expectEq(sortedArr[0], 1, "arraylist sortBy first")
expectEq(sortedArr[2], 3, "arraylist sortBy last")

let beforeCap = sortable.capacity
sortable.reserve(10)
expectTrue(sortable.capacity - sortable.size >= 10, "arraylist reserve additional")
expectTrue(sortable.capacity >= beforeCap, "arraylist reserve grows")

let listString = sortable.toString()
expectTrue(listString.contains("1"), "arraylist toString contains 1")
let snapshot = sortable.toArray()
sortable.add(9)
expectEq(snapshot.size, 3, "arraylist toArray snapshot")

sortable.clear()
expectTrue(sortable.isEmpty(), "arraylist clear")
expectFalse(sortable.contains(1), "arraylist contains after clear")
let emptyIter = sortable.iterator()
expectTrue(emptyIter() == None, "arraylist iterator empty")
let emptyList = ArrayList()
emptyList.reverse()
expectEq(emptyList.size, 0, "arraylist reverse empty")

if (!__test_failed) {
    println("PASS: std/tests/arraylist_functional")
}
