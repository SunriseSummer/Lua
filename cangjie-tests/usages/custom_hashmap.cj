dofile("cangjie-tests/_testing.cj")

// Test: Custom HashMap implementation

struct LHashMap<K, V> {
  var data = nil
  var keys = nil
  var count: Int64

  init() {
    this.data = {}
    this.count = 0
    this.keys = {}
  }

  func size(): Int64 {
    return this.count
  }

  func isEmpty(): Bool {
    return this.count == 0
  }

  func put(key: K, value: V) {
    if (this.data[key] == nil) {
      this.count = this.count + 1
      this.keys[this.count] = key
    }
    this.data[key] = value
  }

  func get(key: K): V {
    return this.data[key]
  }

  func containsKey(key: K): Bool {
    return this.data[key] != nil
  }

  func remove(key: K): Bool {
    if (this.data[key] != nil) {
      this.data[key] = nil
      this.count = this.count - 1
      var i = 1
      while (i <= #this.keys) {
        if (this.keys[i] == key) {
          table.remove(this.keys, i)
          break
        }
        i = i + 1
      }
      return true
    }
    return false
  }

  func forEach(fn) {
    var i = 1
    while (i <= #this.keys) {
      let k = this.keys[i]
      if (this.data[k] != nil) {
        fn(k, this.data[k])
      }
      i = i + 1
    }
  }

  func toString(): String {
    var result = "{"
    var first = true
    var i = 1
    while (i <= #this.keys) {
      let k = this.keys[i]
      if (this.data[k] != nil) {
        if (!first) {
          result = result + ", "
        }
        result = result + tostring(k) + ": " + tostring(this.data[k])
        first = false
      }
      i = i + 1
    }
    return result + "}"
  }
}

// -- Section: basic operations --
let map = LHashMap()
expectTrue(map.isEmpty(), "empty map")
expectEq(map.size(), 0, "empty map size")

// -- Section: put and get --
map.put("name", "Cangjie")
map.put("version", 1)
map.put("type", "language")
expectEq(map.get("name"), "Cangjie", "get name")
expectEq(map.get("version"), 1, "get version")
expectEq(map.size(), 3, "size after 3 puts")

// -- Section: containsKey --
expectTrue(map.containsKey("name"), "containsKey name")
expectFalse(map.containsKey("missing"), "containsKey missing")

// -- Section: put update --
map.put("version", 2)
expectEq(map.get("version"), 2, "updated version")
expectEq(map.size(), 3, "size unchanged after update")

// -- Section: remove --
map.remove("type")
expectEq(map.size(), 2, "size after remove")
expectFalse(map.containsKey("type"), "type removed")

// -- Section: forEach --
var forEach_keys = ""
map.forEach(func(k, v) {
  forEach_keys = forEach_keys + tostring(k) + " "
})
expectTrue(string.find(forEach_keys, "name", 1, true) != nil, "forEach has name")
expectTrue(string.find(forEach_keys, "version", 1, true) != nil, "forEach has version")

// -- Section: integer keys --
let intMap = LHashMap()
intMap.put(1, "one")
intMap.put(2, "two")
intMap.put(3, "three")
expectEq(intMap.get(2), "two", "intMap get(2)")
expectEq(intMap.size(), 3, "intMap size")

if (!__test_failed) {
    println("PASS: usages/custom_hashmap")
}
