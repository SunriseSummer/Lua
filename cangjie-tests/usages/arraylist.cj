// Test: ArrayList implementation
// A dynamic array with automatic resizing

struct ArrayList<T> {
  var data: Array<T>
  var length: Int64

  init() {
    this.data = {}
    this.length = 0
  }

  func size(): Int64 {
    return this.length
  }

  func isEmpty(): Bool {
    return this.length == 0
  }

  func add(item: T) {
    this.length = this.length + 1
    this.data[this.length] = item
  }

  func get(index: Int64): T {
    if (index < 0 || index >= this.length) {
      return nil
    }
    return this.data[index + 1]
  }

  func set(index: Int64, value: T) {
    if (index >= 0 && index < this.length) {
      this.data[index + 1] = value
    }
  }

  func removeAt(index: Int64): T {
    if (index < 0 || index >= this.length) {
      return nil
    }
    let removed = this.data[index + 1]
    // shift elements left
    var i = index + 1
    while (i < this.length) {
      this.data[i] = this.data[i + 1]
      i = i + 1
    }
    this.data[this.length] = nil
    this.length = this.length - 1
    return removed
  }

  func indexOf(item: T): Int64 {
    var i = 1
    while (i <= this.length) {
      if (this.data[i] == item) {
        return i - 1
      }
      i = i + 1
    }
    return -1
  }

  func contains(item: T): Bool {
    return this.indexOf(item) != -1
  }

  func clear() {
    this.data = {}
    this.length = 0
  }

  func toString(): String {
    var result = "["
    var i = 1
    while (i <= this.length) {
      if (i > 1) {
        result = result + ", "
      }
      result = result + tostring(this.data[i])
      i = i + 1
    }
    return result + "]"
  }

  func forEach(fn) {
    var i = 1
    while (i <= this.length) {
      fn(this.data[i], i - 1)
      i = i + 1
    }
  }

  func map(fn) {
    let result = ArrayList()
    var i = 1
    while (i <= this.length) {
      result.add(fn(this.data[i]))
      i = i + 1
    }
    return result
  }

  func filter(fn) {
    let result = ArrayList()
    var i = 1
    while (i <= this.length) {
      if (fn(this.data[i])) {
        result.add(this.data[i])
      }
      i = i + 1
    }
    return result
  }
}

// === Tests ===

// Test basic operations
let list = ArrayList()
println("empty: ${tostring(list.isEmpty())}")  // true
println("size: ${list.size()}")                // 0

// Test add
list.add(10)
list.add(20)
list.add(30)
list.add(40)
list.add(50)
println("after add: ${list.toString()}")  // [10, 20, 30, 40, 50]
println("size: ${list.size()}")           // 5

// Test get (0-based index)
println("get(0): ${list.get(0)}")  // 10
println("get(2): ${list.get(2)}")  // 30
println("get(4): ${list.get(4)}")  // 50

// Test set (0-based index)
list.set(2, 300)
println("after set(2, 300): ${list.toString()}")  // [10, 20, 300, 40, 50]

// Test indexOf and contains
println("indexOf(20): ${list.indexOf(20)}")        // 1
println("indexOf(999): ${list.indexOf(999)}")      // -1
println("contains(40): ${tostring(list.contains(40))}")  // true
println("contains(99): ${tostring(list.contains(99))}")  // false

// Test removeAt (0-based index)
let removed = list.removeAt(1)
println("removed: ${removed}")                      // 20
println("after remove: ${list.toString()}")          // [10, 300, 40, 50]
println("size: ${list.size()}")                      // 4

// Test forEach
print("forEach: ")
list.forEach(func(item, idx) {
  print("${item} ")
})
println()  // 10 300 40 50

// Test map
let doubled = list.map(func(x) { return x * 2 })
println("map(*2): ${doubled.toString()}")  // [20, 600, 80, 100]

// Test filter
let big = list.filter(func(x) { return x > 30 })
println("filter(>30): ${big.toString()}")  // [300, 40, 50]

// Test clear
list.clear()
println("after clear: ${list.toString()}")  // []
println("size: ${list.size()}")              // 0

println("PASS: 09_arraylist")
