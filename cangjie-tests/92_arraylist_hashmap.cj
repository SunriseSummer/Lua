dofile("cangjie-tests/_testing.cj")

// Test: ArrayList and HashMap native collections

let list = ArrayList()
expectTrue(list.isEmpty(), "arraylist empty")
expectEq(list.size, 0, "arraylist size 0")
expectTrue(list.capacity >= 16, "arraylist default capacity")
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
let raw = list.getRawArray()
expectEq(raw.size, list.size, "arraylist raw size")
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

let map = HashMap()
expectTrue(map.isEmpty(), "hashmap empty")
expectEq(map.size, 0, "hashmap size 0")
expectTrue(map.capacity >= 16, "hashmap capacity")
let add_result = map.add("a", 1)
expectTrue(add_result.isNone(), "hashmap add none")
map.add("b", 2)
map.addIfAbsent("b", 9)
expectEq(map["b"], 2, "hashmap addIfAbsent")
expectEq(map.size, 2, "hashmap size 2")
expectEq(map.get("a").getOrDefault({=> 0}), 1, "hashmap get")
expectTrue(map.get("missing").isNone(), "hashmap get missing")
expectTrue(map.contains("b"), "hashmap contains b")
expectTrue(map.contains(["a", "b"]), "hashmap contains all")
let replaced = map.replace("b", 3)
expectEq(replaced.getOrDefault({=> 0}), 2, "hashmap replace old")
expectEq(map["b"], 3, "hashmap index")
map["c"] = 4
expectEq(map["c"], 4, "hashmap index set")
expectRuntimeError("hashmap index missing", "let m = HashMap(); let _ = m[\"missing\"]", "key not found")
let entry = map.entryView("d")
expectTrue(entry.value.isNone(), "entryView empty")
entry.value = Some(8)
expectEq(map.get("d").getOrDefault({=> 0}), 8, "entryView set")
entry.value = None
expectTrue(map.get("d").isNone(), "entryView remove")
let removed_entry = map.remove("a")
expectEq(removed_entry.getOrDefault({=> 0}), 1, "hashmap remove")
map.remove(["b"])
expectTrue(map.get("b").isNone(), "hashmap remove all")
map.add("x", 1)
map.add("y", 2)
map.removeIf({ k, v => v == 2 })
expectTrue(map.get("y").isNone(), "hashmap removeIf")

let keys = map.keys()
let values = map.values()
expectEq(keys.size, 1, "hashmap keys size")
expectEq(values.size, 1, "hashmap values size")
expectTrue(keys.contains("c"), "hashmap keys contains")
expectTrue(values.contains(4), "hashmap values contains")
let map_iter = map.iterator()
var pair_count = 0
while (let Some(pair) <- map_iter()) {
    pair_count = pair_count + 1
}
expectEq(pair_count, map.size, "hashmap iterator count")
let map_arr = map.toArray()
expectEq(map_arr.size, map.size, "hashmap toArray size")
let map_clone = map.clone()
expectTrue(map_clone == map, "hashmap clone eq")
map_clone.add("z", 9)
expectTrue(map_clone != map, "hashmap clone ne")
let map_str = map.toString()
expectTrue(string.find(map_str, "(c, 4)", 1, true) != nil, "hashmap toString")
let map_cap = map.capacity
map.reserve(2)
expectTrue(map.capacity >= map_cap, "hashmap reserve")
map.clear()
expectTrue(map.isEmpty(), "hashmap clear")

if (!__test_failed) {
    println("PASS: arraylist_hashmap")
}
