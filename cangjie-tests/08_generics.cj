// Test: Generics

// Generic function with type parameter annotation
func identity<T>(x) {
  return x
}
println("identity(42) = ${identity(42)}")
let hw = identity("hello")
println("identity(hello) = ${hw}")

// Generic struct
struct Box<T> {
  func new(value) {
    self.value = value
    return self
  }
  func get() {
    return self.value
  }
  func toString() {
    return "Box(" .. tostring(self.value) .. ")"
  }
}

func newBox(value) {
  let b = setmetatable({}, Box)
  b:new(value)
  return b
}

let intBox = newBox(42)
let strBox = newBox("hello")
println(intBox:toString())
println(strBox:toString())
println("intBox.get() = ${intBox:get()}")

// Generic function: swap
func swap<T>(a, b) {
  return b, a
}
let x, y = swap(1, 2)
println("swap(1, 2) = ${x}, ${y}")

// Generic Stack
struct Stack<T> {
  func new() {
    self.items = {}
    self.size = 0
    return self
  }
  func push(item) {
    self.size = self.size + 1
    self.items[self.size] = item
  }
  func pop() {
    if self.size == 0 {
      return nil
    }
    let item = self.items[self.size]
    self.items[self.size] = nil
    self.size = self.size - 1
    return item
  }
  func peek() {
    return self.items[self.size]
  }
  func isEmpty() {
    return self.size == 0
  }
}

func newStack() {
  let s = setmetatable({}, Stack)
  s:new()
  return s
}

let stack = newStack()
stack:push(10)
stack:push(20)
stack:push(30)
println("peek: ${stack:peek()}")
println("pop: ${stack:pop()}")
println("pop: ${stack:pop()}")
println("empty: ${tostring(stack:isEmpty())}")
println("pop: ${stack:pop()}")
println("empty: ${tostring(stack:isEmpty())}")

println("PASS: 08_generics")
