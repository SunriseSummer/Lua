// Test: HashMap implementation

struct HashMap<K, V> {
  func new() {
    self.data = {}
    self.count = 0
    self.keys_list = {}
    return self
  }
  func size() {
    return self.count
  }
  func isEmpty() {
    return self.count == 0
  }
  func put(key, value) {
    if self.data[key] == nil {
      self.count = self.count + 1
      self.keys_list[self.count] = key
    }
    self.data[key] = value
  }
  func get(key) {
    return self.data[key]
  }
  func containsKey(key) {
    return self.data[key] != nil
  }
  func remove(key) {
    if self.data[key] != nil {
      self.data[key] = nil
      self.count = self.count - 1
      var i = 1
      while i <= #self.keys_list {
        if self.keys_list[i] == key {
          table.remove(self.keys_list, i)
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
    while i <= #self.keys_list {
      let k = self.keys_list[i]
      if self.data[k] != nil {
        fn(k, self.data[k])
      }
      i = i + 1
    }
  }
  func toString() {
    var result = "{"
    var first = true
    var i = 1
    while i <= #self.keys_list {
      let k = self.keys_list[i]
      if self.data[k] != nil {
        if not first {
          result = result .. ", "
        }
        result = result .. tostring(k) .. ": " .. tostring(self.data[k])
        first = false
      }
      i = i + 1
    }
    return result .. "}"
  }
}

func newHashMap() {
  let m = setmetatable({}, HashMap)
  m:new()
  return m
}

// === Tests ===

let map = newHashMap()
println("empty: ${tostring(map:isEmpty())}")
println("size: ${map:size()}")

map:put("name", "Cangjie")
map:put("version", 1)
map:put("type", "language")
println("after put: ${map:toString()}")

let gn = map:get("name")
let gv = map:get("version")
println("get name: ${gn}")
println("get version: ${gv}")
println("size: ${map:size()}")

let hk = map:containsKey("name")
println("has name: ${tostring(hk)}")

map:put("version", 2)
let gv2 = map:get("version")
println("updated version: ${gv2}")

map:remove("type")
println("after remove: ${map:toString()}")
println("size: ${map:size()}")

print("forEach: ")
map:forEach(func(k, v) {
  print(tostring(k) .. "=" .. tostring(v) .. " ")
})
println()

// Test with integer keys
let intMap = newHashMap()
intMap:put(1, "one")
intMap:put(2, "two")
intMap:put(3, "three")
println("intMap: ${intMap:toString()}")
let ig = intMap:get(2)
println("intMap[2] = ${ig}")

println("PASS: 10_hashmap")
