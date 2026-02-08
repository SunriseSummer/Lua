dofile("cangjie-tests/_testing.cj")

// Usage: Generic collections with interfaces
// Demonstrates a generic Stack<T> used with Int64, String, and custom structs.

// -- Generic Stack implementation --
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
        if (this.count == 0) { return nil }
        let item = this.items[this.count]
        this.items[this.count] = nil
        this.count = this.count - 1
        return item
    }
    func peek(): T {
        if (this.count == 0) { return nil }
        return this.items[this.count]
    }
    func isEmpty(): Bool {
        return this.count == 0
    }
    func size(): Int64 {
        return this.count
    }
}

// -- Section: Stack with Int64 --
let intStack = Stack()
expectTrue(intStack.isEmpty(), "int stack empty")
intStack.push(10)
intStack.push(20)
intStack.push(30)
expectEq(intStack.size(), 3, "int stack size 3")
expectEq(intStack.peek(), 30, "int stack peek")
expectEq(intStack.pop(), 30, "int stack pop 30")
expectEq(intStack.pop(), 20, "int stack pop 20")
expectEq(intStack.pop(), 10, "int stack pop 10")
expectTrue(intStack.isEmpty(), "int stack empty after pops")
expectNil(intStack.pop(), "int stack pop empty is nil")

// -- Section: Stack with String --
let strStack = Stack()
strStack.push("hello")
strStack.push("world")
expectEq(strStack.size(), 2, "str stack size 2")
expectEq(strStack.peek(), "world", "str stack peek")
expectEq(strStack.pop(), "world", "str stack pop world")
expectEq(strStack.pop(), "hello", "str stack pop hello")
expectTrue(strStack.isEmpty(), "str stack empty after pops")

// -- Section: Custom struct with Stack --
struct Item {
    var name: String
    var value: Int64
    init(name: String, value: Int64) {
        this.name = name
        this.value = value
    }
}

let itemStack = Stack()
itemStack.push(Item("sword", 100))
itemStack.push(Item("shield", 50))
itemStack.push(Item("potion", 25))
expectEq(itemStack.size(), 3, "item stack size 3")

let top = itemStack.pop()
expectEq(top.name, "potion", "item stack pop name")
expectEq(top.value, 25, "item stack pop value")

let mid = itemStack.peek()
expectEq(mid.name, "shield", "item stack peek name")

// -- Section: Using stack for reverse operation --
let revStack = Stack()
for (i in 1..=5) {
    revStack.push(i)
}
var reversed = ""
while (!revStack.isEmpty()) {
    reversed = reversed .. tostring(revStack.pop())
}
expectEq(reversed, "54321", "stack reversal")

// -- Section: Multiple independent stacks --
let s1 = Stack()
let s2 = Stack()
s1.push(1)
s1.push(2)
s2.push(10)
s2.push(20)
expectEq(s1.pop(), 2, "s1 independent")
expectEq(s2.pop(), 20, "s2 independent")
expectEq(s1.size(), 1, "s1 size")
expectEq(s2.size(), 1, "s2 size")

if (!__test_failed) {
    println("PASS: usages/generic_collections")
}
