dofile("cangjie-tests/_testing.cj")

// Test: Static member functions (static func)

// Struct with static functions
struct MathUtils {
  var value: Int64

  init(v: Int64) {
    this.value = v
  }

  static func add(a: Int64, b: Int64): Int64 {
    return a + b
  }

  static func multiply(a: Int64, b: Int64): Int64 {
    return a * b
  }

  static func zero(): Int64 {
    return 0
  }

  func doubleValue(): Int64 {
    return value * 2
  }

  // Instance method calling static method
  func addToValue(n: Int64): Int64 {
    return add(value, n)
  }
}

// Call static functions via type name
let sum = MathUtils.add(3, 4)
expectEq(sum, 7, "MathUtils.add(3, 4)")

let product = MathUtils.multiply(5, 6)
expectEq(product, 30, "MathUtils.multiply(5, 6)")

let z = MathUtils.zero()
expectEq(z, 0, "MathUtils.zero()")

// Instance methods still work
let m = MathUtils(10)
let doubled = m.doubleValue()
expectEq(doubled, 20, "m.doubleValue()")

// Calling static from within instance method
let added = m.addToValue(5)
expectEq(added, 15, "m.addToValue(5)")

// Class with static functions
class Counter {
  var count: Int64

  init() {
    this.count = 0
  }

  static func create(): Counter {
    return Counter()
  }

  func increment() {
    count = count + 1
  }

  func getCount(): Int64 {
    return count
  }
}

let c = Counter.create()
c.increment()
c.increment()
c.increment()
expectEq(c.getCount(), 3, "counter after 3 increments")

// Static with complex logic
struct StringHelper {
  var text: String

  init(t: String) {
    this.text = t
  }

  static func repeat(s: String, n: Int64): String {
    var result = ""
    var i = 0
    while (i < n) {
      result = result + s
      i = i + 1
    }
    return result
  }

  func repeated(n: Int64): String {
    return repeat(text, n)
  }
}

let stars = StringHelper.repeat("*", 5)
expectEq(stars, "*****", "StringHelper.repeat('*', 5)")

let sh = StringHelper("ab")
let rep = sh.repeated(3)
expectEq(rep, "ababab", "sh.repeated(3)")

if (!__test_failed) {
    println("PASS: 19_static_func")
}
