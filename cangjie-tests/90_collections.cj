dofile("cangjie-tests/_testing.cj")

// ArrayList
let list = ArrayList()
expectTrue(list.isEmpty(), "ArrayList empty")
list.add(1)
list.add(2)
list.add(3, 1)
expectEq(list.size, 3, "ArrayList size")
expectEq(list[0], 1, "ArrayList index 0")
expectEq(list[1], 3, "ArrayList insert at")
expectEq(list.get(1).getOrDefault(0), 3, "ArrayList get option")
expectEq(list.first.getOrDefault(0), 1, "ArrayList first")
expectEq(list.last.getOrDefault(0), 2, "ArrayList last")
expectEq(list.remove(1), 3, "ArrayList remove index")
list.add([4, 5])
expectEq(list.size, 4, "ArrayList add collection")
let slice = list.slice(1..2)
expectEq(slice.size, 2, "ArrayList slice size")
let mapped = list.map({ v: Int64 => v + 1 })
expectEq(mapped[0], 2, "ArrayList map")
let filtered = list.filter({ v: Int64 => v > 2 })
expectTrue(filtered.contains(4), "ArrayList filter")
let listIter = list.iterator()
match (listIter.next()) {
    case Some(v) => expectEq(v, 1, "ArrayList iterator next")
    case None => expectTrue(false, "ArrayList iterator missing")
}

// ArrayStack
let stack = ArrayStack()
expectTrue(stack.isEmpty(), "ArrayStack empty")
stack.add(10)
stack.add(20)
expectEq(stack.peek().getOrDefault(0), 20, "ArrayStack peek")
expectEq(stack.remove().getOrDefault(0), 20, "ArrayStack remove")
expectEq(stack.size, 1, "ArrayStack size")
let stackArr = stack.toArray()
expectEq(stackArr.size, 1, "ArrayStack toArray size")
expectEq(stackArr[0], 10, "ArrayStack toArray value")
let stackIter = stack.iterator()
match (stackIter.next()) {
    case Some(v) => expectEq(v, 10, "ArrayStack iterator next")
    case None => expectTrue(false, "ArrayStack iterator missing")
}

// HashMap
let map = HashMap()
expectTrue(map.isEmpty(), "HashMap empty")
map.add("a", 1)
expectEq(map.get("a").getOrDefault(0), 1, "HashMap get")
expectTrue(map.contains("a"), "HashMap contains key")
map["b"] = 2
expectEq(map["b"], 2, "HashMap index get")
expectEq(map.add("a", 3).getOrDefault(0), 1, "HashMap add returns old")
expectEq(map.addIfAbsent("a", 4).getOrDefault(0), 3, "HashMap addIfAbsent")
expectEq(map.replace("a", 5).getOrDefault(0), 3, "HashMap replace")
let entry = map.entryView("c")
expectTrue(entry.value.isNone(), "HashMap entryView empty")
entry.value = 7
expectEq(map.get("c").getOrDefault(0), 7, "HashMap entryView set")
entry.value = None
expectFalse(map.contains("c"), "HashMap entryView remove")
let keys = map.keys()
expectEq(keys.size, map.size, "HashMap keys size")
let vals = map.values()
expectEq(vals.size, map.size, "HashMap values size")
let mapIter = map.iterator()
match (mapIter.next()) {
    case Some(kv) => expectTrue(map.contains(kv[0]), "HashMap iterator key")
    case None => expectTrue(false, "HashMap iterator missing")
}

// HashSet
let set = HashSet()
expectTrue(set.isEmpty(), "HashSet empty")
expectTrue(set.add(1), "HashSet add new")
expectFalse(set.add(1), "HashSet add duplicate")
set.add([2, 3])
expectTrue(set.contains(2), "HashSet contains")
expectTrue(set.contains([1, 2]), "HashSet contains all")
expectTrue(set.remove(3), "HashSet remove")
expectFalse(set.remove(9), "HashSet remove missing")
let setB = HashSet([1, 2, 4])
expectTrue(set.subsetOf(setB), "HashSet subsetOf")
let unionSet = set | setB
expectTrue(unionSet.contains([1, 2, 4]), "HashSet union")
let interSet = set & setB
expectTrue(interSet.contains(1), "HashSet intersect")
let diffSet = unionSet - setB
expectFalse(diffSet.contains(1), "HashSet diff")
let setIter = set.iterator()
match (setIter.next()) {
    case Some(v) => expectTrue(set.contains(v), "HashSet iterator next")
    case None => expectTrue(false, "HashSet iterator missing")
}

if (!__test_failed) {
    println("PASS: 90_collections")
}
