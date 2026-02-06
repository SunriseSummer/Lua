// Test: ArrayList implementation
// A dynamic array with automatic resizing

struct ArrayList<T> {
  func new() {
    self.data = {}
    self.length = 0
    return self
  }

  func size() {
    return self.length
  }

  func isEmpty() {
    return self.length == 0
  }

  func add(item) {
    self.length = self.length + 1
    self.data[self.length] = item
  }

  func get(index) {
    if index < 1 or index > self.length {
      return nil
    }
    return self.data[index]
  }

  func set(index, value) {
    if index >= 1 and index <= self.length {
      self.data[index] = value
    }
  }

  func removeAt(index) {
    if index < 1 or index > self.length {
      return nil
    }
    let removed = self.data[index]
    // shift elements left
    var i = index
    while i < self.length {
      self.data[i] = self.data[i + 1]
      i = i + 1
    }
    self.data[self.length] = nil
    self.length = self.length - 1
    return removed
  }

  func indexOf(item) {
    var i = 1
    while i <= self.length {
      if self.data[i] == item {
        return i
      }
      i = i + 1
    }
    return -1
  }

  func contains(item) {
    return self:indexOf(item) != -1
  }

  func clear() {
    self.data = {}
    self.length = 0
  }

  func toString() {
    var result = "["
    var i = 1
    while i <= self.length {
      if i > 1 {
        result = result .. ", "
      }
      result = result .. tostring(self.data[i])
      i = i + 1
    }
    return result .. "]"
  }

  func forEach(fn) {
    var i = 1
    while i <= self.length {
      fn(self.data[i], i)
      i = i + 1
    }
  }

  func map(fn) {
    let result = newArrayList()
    var i = 1
    while i <= self.length {
      result:add(fn(self.data[i]))
      i = i + 1
    }
    return result
  }

  func filter(fn) {
    let result = newArrayList()
    var i = 1
    while i <= self.length {
      if fn(self.data[i]) {
        result:add(self.data[i])
      }
      i = i + 1
    }
    return result
  }
}

func newArrayList() {
  let list = setmetatable({}, ArrayList)
  list:new()
  return list
}

// === Tests ===

// Test basic operations
let list = newArrayList()
println("empty: ${tostring(list:isEmpty())}")  // true
println("size: ${list:size()}")                // 0

// Test add
list:add(10)
list:add(20)
list:add(30)
list:add(40)
list:add(50)
println("after add: ${list:toString()}")  // [10, 20, 30, 40, 50]
println("size: ${list:size()}")           // 5

// Test get
println("get(1): ${list:get(1)}")  // 10
println("get(3): ${list:get(3)}")  // 30
println("get(5): ${list:get(5)}")  // 50

// Test set
list:set(3, 300)
println("after set(3, 300): ${list:toString()}")  // [10, 20, 300, 40, 50]

// Test indexOf and contains
println("indexOf(20): ${list:indexOf(20)}")        // 2
println("indexOf(999): ${list:indexOf(999)}")      // -1
println("contains(40): ${tostring(list:contains(40))}")  // true
println("contains(99): ${tostring(list:contains(99))}")  // false

// Test removeAt
let removed = list:removeAt(2)
println("removed: ${removed}")                      // 20
println("after remove: ${list:toString()}")          // [10, 300, 40, 50]
println("size: ${list:size()}")                      // 4

// Test forEach
print("forEach: ")
list:forEach(func(item, idx) {
  print("${item} ")
})
println()  // 10 300 40 50

// Test map
let doubled = list:map(func(x) { return x * 2 })
println("map(*2): ${doubled:toString()}")  // [20, 600, 80, 100]

// Test filter
let big = list:filter(func(x) { return x > 30 })
println("filter(>30): ${big:toString()}")  // [300, 40, 50]

// Test clear
list:clear()
println("after clear: ${list:toString()}")  // []
println("size: ${list:size()}")              // 0

println("PASS: 09_arraylist")
