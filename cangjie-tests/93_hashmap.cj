dofile("cangjie-tests/_testing.cj")

// Test: HashMap native collection

let map = HashMap()
expectTrue(map.isEmpty(), "hashmap empty")
expectEq(map.size, 0, "hashmap size 0")
expectTrue(map.capacity >= 16, "hashmap capacity")
expectEq(map.toString(), "[]", "hashmap empty tostring")

let add_result = map.add("a", 1)
expectTrue(add_result.isNone(), "hashmap add none")
map.add("b", 2)
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

let view = map.entryView("d")
expectTrue(view.value.isNone(), "entryView empty")
view.value = Some(8)
expectEq(map.get("d").getOrDefault({=> 0}), 8, "entryView set")
view.value = None
expectTrue(map.get("d").isNone(), "entryView remove")

let removed_entry = map.remove("a")
expectEq(removed_entry.getOrDefault({=> 0}), 1, "hashmap remove")
map.remove(["b"])
expectTrue(map.get("b").isNone(), "hashmap remove all")

map.add("x", 1)
map.add("y", 2)
map.removeIf({ k, v => v == 2 })
expectTrue(map.get("y").isNone(), "hashmap removeIf")

let tuple_add = [("m", 9), ("n", 10)]
map.add(tuple_add)
expectTrue(map.contains(["m", "n"]), "hashmap add collection")

let map2 = HashMap()
map2.add("p", 11)
map2.add("q", 12)
map.add(map2)
expectTrue(map.contains(["p", "q"]), "hashmap add hashmap")

let map_str = map.toString()
expectTrue(string.find(map_str, "4", 1, true) != nil, "hashmap toString")

let map_cap = map.capacity
map.reserve(2)
expectTrue(map.capacity >= map_cap, "hashmap reserve")
map.clear()
expectTrue(map.isEmpty(), "hashmap clear")

let small = HashMap()
small.add("k", 7)
small.add("v", 9)
let keys = small.keys()
let values = small.values()
expectEq(keys.size, small.size, "hashmap keys size")
expectEq(values.size, small.size, "hashmap values size")

let map_iter = small.iterator()
var pair_count = 0
while (let Some(pair) <- map_iter()) {
    pair_count = pair_count + 1
}
expectEq(pair_count, small.size, "hashmap iterator count")

let map_arr = small.toArray()
expectEq(map_arr.size, small.size, "hashmap toArray size")

let map_clone = small.clone()
expectTrue(map_clone == small, "hashmap clone eq")
map_clone.add("z", 10)
expectTrue(map_clone != small, "hashmap clone ne")

if (!__test_failed) {
    println("PASS: hashmap")
}
