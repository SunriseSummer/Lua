// Test: Generics
// Validates generic functions, generic structs, and generic stack operations.

// -- Section: Generic identity function --
func identity<T>(x: T): T {
  return x
}
let r_id_int = identity(42)
if (r_id_int != 42) { println("FAIL: identity(42) expected 42, got ${r_id_int}"); return () }
let r_id_str = identity("hello")
if (r_id_str != "hello") { println("FAIL: identity('hello') expected 'hello', got ${r_id_str}"); return () }

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
let r_intBox = intBox.toString()
if (r_intBox != "Box(42)") { println("FAIL: intBox.toString() expected 'Box(42)', got ${r_intBox}"); return () }
let r_strBox = strBox.toString()
if (r_strBox != "Box(hello)") { println("FAIL: strBox.toString() expected 'Box(hello)', got ${r_strBox}"); return () }
let r_get = intBox.get()
if (r_get != 42) { println("FAIL: intBox.get() expected 42, got ${r_get}"); return () }

// -- Section: Generic swap function --
func swap<T>(a: T, b: T) {
  return b, a
}
let x, y = swap(1, 2)
if (x != 2) { println("FAIL: swap(1,2) first expected 2, got ${x}"); return () }
if (y != 1) { println("FAIL: swap(1,2) second expected 1, got ${y}"); return () }

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
let r_peek = stack.peek()
if (r_peek != 30) { println("FAIL: peek expected 30, got ${r_peek}"); return () }
let r_pop1 = stack.pop()
if (r_pop1 != 30) { println("FAIL: first pop expected 30, got ${r_pop1}"); return () }
let r_pop2 = stack.pop()
if (r_pop2 != 20) { println("FAIL: second pop expected 20, got ${r_pop2}"); return () }
let r_empty1 = stack.isEmpty()
if (r_empty1 != false) { println("FAIL: isEmpty after 2 pops expected false, got ${r_empty1}"); return () }
let r_pop3 = stack.pop()
if (r_pop3 != 10) { println("FAIL: third pop expected 10, got ${r_pop3}"); return () }
let r_empty2 = stack.isEmpty()
if (r_empty2 != true) { println("FAIL: isEmpty after all pops expected true, got ${r_empty2}"); return () }

println("PASS: 08_generics")
