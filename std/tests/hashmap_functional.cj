dofile("cangjie-tests/_testing.cj")
dofile("std/HashMap.cj")

let map = HashMap()
expectTrue(map.isEmpty(), "hashmap empty")
expectTrue(map.add("a", 1) == None, "hashmap add returns None")
map.add("b", 2)
expectEq(map.size, 2, "hashmap size after add")
expectEq(map.get("a") ?? -1, 1, "hashmap get a")
expectTrue(map.contains("b"), "hashmap contains b")
expectTrue(map.get("missing") == None, "hashmap get missing")

expectEq(map.replace("b", 3) ?? -1, 2, "hashmap replace b")
expectTrue(map.replace("c", 4) == None, "hashmap replace missing")
expectEq(map.get("b") ?? -1, 3, "hashmap get replaced")

expectEq(map.remove("a") ?? -1, 1, "hashmap remove a")
expectFalse(map.contains("a"), "hashmap removed a")

map.add("c", 4)
map.add("d", 5)
expectEq(map.add("c", 7) ?? -1, 4, "hashmap add returns old")
map.removeIf({ k, v => v % 2 == 1 })
expectFalse(map.contains("b"), "hashmap removeIf removed b")
expectFalse(map.contains("d"), "hashmap removeIf removed d")
expectTrue(map.contains("c"), "hashmap removeIf kept c")

let keys = map.keys()
let values = map.values()
expectEq(keys.size, map.size, "hashmap keys size")
expectEq(values.size, map.size, "hashmap values size")

let entries = map.toArray()
expectEq(entries.size, map.size, "hashmap toArray size")
let iter = map.iterator()
var count = 0
while (let Some(_) <- iter()) {
    count = count + 1
}
expectEq(count, map.size, "hashmap iterator count")

let cloned = map.clone()
cloned.add("e", 9)
expectFalse(map.contains("e"), "hashmap clone independent")
expectTrue(map.remove("missing") == None, "hashmap remove missing")

let beforeCap = map.capacity
map.reserve(6)
expectTrue(map.capacity - map.size >= 6, "hashmap reserve additional")
expectTrue(map.capacity >= beforeCap, "hashmap reserve grows")

let mapString = map.toString()
expectTrue(mapString.contains("c"), "hashmap toString contains key")

map.clear()
expectTrue(map.isEmpty(), "hashmap clear")
let emptyIter = map.iterator()
expectTrue(emptyIter() == None, "hashmap iterator empty")

if (!__test_failed) {
    println("PASS: std/tests/hashmap_functional")
}
