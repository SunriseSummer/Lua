dofile("cangjie-tests/_testing.cj")

// Test: Generics
// Validates generic functions, generic structs, and generic stack operations.

// -- Section: Generic identity function --
func identity<T>(x: T): T {
  return x
}
expectEq(identity(42), 42, "identity(42)")
expectEq(identity("hello"), "hello", "identity('hello')")

// -- Section: Generic struct Box --
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
expectEq(intBox.toString(), "Box(42)", "intBox.toString()")
expectEq(strBox.toString(), "Box(hello)", "strBox.toString()")
expectEq(intBox.get(), 42, "intBox.get()")

// -- Section: Generic swap function --
func swap<T>(a: T, b: T) {
  return b, a
}
let x, y = swap(1, 2)
expectEq(x, 2, "swap(1,2) first")
expectEq(y, 1, "swap(1,2) second")

// -- Section: Generic Stack --
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
expectEq(stack.peek(), 30, "peek")
expectEq(stack.pop(), 30, "first pop")
expectEq(stack.pop(), 20, "second pop")
expectFalse(stack.isEmpty(), "isEmpty after 2 pops")
expectEq(stack.pop(), 10, "third pop")
expectTrue(stack.isEmpty(), "isEmpty after all pops")

if (!__test_failed) {
  println("PASS: 09_generics")
}
