dofile("cangjie-tests/_testing.cj")

// Test: ArrayList native collection

struct TestRange {
    var start: Int64
    var end: Int64
    var step: Int64
    var hasEnd: Int64
    var isClosed: Int64

    init(start: Int64, end: Int64, isClosed: Int64) {
        this.start = start
        this.end = end
        this.step = 1
        this.hasEnd = 1
        this.isClosed = isClosed
    }
}

let list = ArrayList()
expectTrue(list.isEmpty(), "arraylist empty")
expectEq(list.size, 0, "arraylist size 0")
expectTrue(list.capacity >= 16, "arraylist capacity")
expectEq(list.toString(), "[]", "arraylist empty tostring")

list.add(10)
list.add(20)
list.add(30)
expectEq(list.size, 3, "arraylist size 3")
expectEq(list.get(1).getOrDefault({=> 0}), 20, "arraylist get")
expectTrue(list.get(9).isNone(), "arraylist get out of range")
expectEq(list[0], 10, "arraylist index")
list[1] = 25
expectEq(list[1], 25, "arraylist set index")

list.add([40, 50])
expectEq(list.size, 5, "arraylist add collection")
list.add(15, 1)
expectEq(list[1], 15, "arraylist add at index")
list.add([5, 6], 0)
expectEq(list[0], 5, "arraylist add collection at index")

let removed = list.remove(1)
expectEq(removed, 6, "arraylist remove")
list.remove(TestRange(2, 3, 1))
expectEq(list.size, 5, "arraylist remove range")

list.removeIf({ v => v == 25 })
expectFalse(list.contains(25), "arraylist removeIf")
expectTrue(list.contains(40), "arraylist contains")
expectEq(list.first.getOrDefault({=> 0}), 5, "arraylist first")
expectEq(list.last.getOrDefault({=> 0}), 50, "arraylist last")

list.reverse()
expectEq(list.first.getOrDefault({=> 0}), 50, "arraylist reverse first")
let slice = list.slice(TestRange(1, 2, 1))
expectEq(slice.size, 2, "arraylist slice size")
expectEq(slice.toString(), "[40, 30]", "arraylist slice tostring")

let list_arr = list.toArray()
expectEq(list_arr.size, list.size, "arraylist toArray size")
let iter = list.iterator()
var list_count = 0
while (let Some(v) <- iter()) {
    list_count = list_count + 1
}
expectEq(list_count, list.size, "arraylist iterator count")

list.sortBy({ a, b => a - b })
expectEq(list[0], 5, "arraylist sortBy asc")
list.sortBy(true, { a, b => b - a })
expectEq(list[0], 50, "arraylist sortBy desc")

let cloned = list.clone()
expectTrue(cloned == list, "arraylist clone eq")
cloned.add(99)
expectTrue(cloned != list, "arraylist clone ne")

let cap_before = list.capacity
list.reserve(3)
expectTrue(list.capacity >= cap_before, "arraylist reserve")
expectRuntimeError("arraylist remove oob", "let l = ArrayList(); l.add(1); l.remove(9)", "index out of range")

list.clear()
expectTrue(list.isEmpty(), "arraylist clear")
expectEq(list.toString(), "[]", "arraylist clear tostring")

if (!__test_failed) {
    println("PASS: arraylist")
}
