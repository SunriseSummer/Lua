dofile("cangjie-tests/_testing.cj")

// Test: ArrayList implementation
// A dynamic array with automatic resizing

struct LArrayList<T> {
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
    let result = LArrayList()
    var i = 1
    while (i <= this.length) {
      result.add(fn(this.data[i]))
      i = i + 1
    }
    return result
  }

  func filter(fn) {
    let result = LArrayList()
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

// -- Section: basic operations --
let list = LArrayList()
expectTrue(list.isEmpty(), "empty list")
expectEq(list.size(), 0, "empty size")

// -- Section: add --
list.add(10)
list.add(20)
list.add(30)
list.add(40)
list.add(50)
expectEq(list.toString(), "[10, 20, 30, 40, 50]", "after add")
expectEq(list.size(), 5, "size after add")

// -- Section: get (0-based) --
expectEq(list.get(0), 10, "get(0)")
expectEq(list.get(2), 30, "get(2)")
expectEq(list.get(4), 50, "get(4)")

// -- Section: set (0-based) --
list.set(2, 300)
expectEq(list.toString(), "[10, 20, 300, 40, 50]", "after set(2, 300)")

// -- Section: indexOf and contains --
expectEq(list.indexOf(20), 1, "indexOf(20)")
expectEq(list.indexOf(999), -1, "indexOf(999)")
expectTrue(list.contains(40), "contains(40)")
expectFalse(list.contains(99), "contains(99)")

// -- Section: removeAt (0-based) --
let removed = list.removeAt(1)
expectEq(removed, 20, "removed value")
expectEq(list.toString(), "[10, 300, 40, 50]", "after remove")
expectEq(list.size(), 4, "size after remove")

// -- Section: forEach --
var forEach_sum = 0
list.forEach(func(item, idx) {
  forEach_sum = forEach_sum + item
})
expectEq(forEach_sum, 400, "forEach sum")

// -- Section: map --
let doubled = list.map(func(x) { return x * 2 })
expectEq(doubled.toString(), "[20, 600, 80, 100]", "map(*2)")

// -- Section: filter --
let big = list.filter(func(x) { return x > 30 })
expectEq(big.toString(), "[300, 40, 50]", "filter(>30)")

// -- Section: clear --
list.clear()
expectEq(list.toString(), "[]", "after clear")
expectEq(list.size(), 0, "size after clear")

if (!__test_failed) {
    println("PASS: usages/custom_arraylist")
}
