// Test: HashMap implementation

struct HashMap<K, V> {
  var data: Array<V>
  var count: Int64
  var keys_list: Array<K>

  init() {
    this.data = {}
    this.count = 0
    this.keys_list = {}
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
      this.keys_list[this.count] = key
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
      while (i <= #this.keys_list) {
        if (this.keys_list[i] == key) {
          table.remove(this.keys_list, i)
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
    while (i <= #this.keys_list) {
      let k = this.keys_list[i]
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
    while (i <= #this.keys_list) {
      let k = this.keys_list[i]
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

// === Tests ===

let map = HashMap()
println("empty: ${tostring(map.isEmpty())}")
println("size: ${map.size()}")

map.put("name", "Cangjie")
map.put("version", 1)
map.put("type", "language")
println("after put: ${map.toString()}")

let gn = map.get("name")
let gv = map.get("version")
println("get name: ${gn}")
println("get version: ${gv}")
println("size: ${map.size()}")

let hk = map.containsKey("name")
println("has name: ${tostring(hk)}")

map.put("version", 2)
let gv2 = map.get("version")
println("updated version: ${gv2}")

map.remove("type")
println("after remove: ${map.toString()}")
println("size: ${map.size()}")

print("forEach: ")
map.forEach(func(k, v) {
  print("${k}=${v} ")
})
println()

// Test with integer keys
let intMap = HashMap()
intMap.put(1, "one")
intMap.put(2, "two")
intMap.put(3, "three")
println("intMap: ${intMap.toString()}")
let ig = intMap.get(2)
println("intMap.get(2) = ${ig}")

println("PASS: 10_hashmap")
