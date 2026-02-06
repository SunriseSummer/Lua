// Test: Generics

// Generic function with type parameter annotation
func identity<T>(x: T): T {
  return x
}
println("identity(42) = ${identity(42)}")
let hw = identity("hello")
println("identity(hello) = ${hw}")

// Generic struct with init/this
struct Box<T> {
  var value: T
  init(value: T) {
    this.value = value
  }
  func get(): T {
    return this.value
  }
  func toString(): String {
    return "Box(${this.value})"
  }
}

let intBox = Box(42)
let strBox = Box("hello")
println(intBox.toString())
println(strBox.toString())
println("intBox.get() = ${intBox.get()}")

// Generic function: swap
func swap<T>(a: T, b: T) {
  return b, a
}
let x, y = swap(1, 2)
println("swap(1, 2) = ${x}, ${y}")

// Generic Stack
struct Stack<T> {
  var items: Array<T>
  var count: Int64
  init() {
    this.items = {}
    this.count = 0
  }
  func push(item: T) {
    this.count = this.count + 1
    this.items[this.count] = item
  }
  func pop(): T {
    if (this.count == 0) {
      return nil
    }
    let item = this.items[this.count]
    this.items[this.count] = nil
    this.count = this.count - 1
    return item
  }
  func peek(): T {
    return this.items[this.count]
  }
  func isEmpty(): Bool {
    return this.count == 0
  }
}

let stack = Stack()
stack.push(10)
stack.push(20)
stack.push(30)
println("peek: ${stack.peek()}")
println("pop: ${stack.pop()}")
println("pop: ${stack.pop()}")
println("empty: ${tostring(stack.isEmpty())}")
println("pop: ${stack.pop()}")
println("empty: ${tostring(stack.isEmpty())}")

println("PASS: 08_generics")
