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
if (sum != 7) {
  println("FAIL: MathUtils.add(3, 4) expected 7, got " + tostring(sum))
  return ()
}

let product = MathUtils.multiply(5, 6)
if (product != 30) {
  println("FAIL: MathUtils.multiply(5, 6) expected 30, got " + tostring(product))
  return ()
}

let z = MathUtils.zero()
if (z != 0) {
  println("FAIL: MathUtils.zero() expected 0, got " + tostring(z))
  return ()
}

// Instance methods still work
let m = MathUtils(10)
let doubled = m.doubleValue()
if (doubled != 20) {
  println("FAIL: m.doubleValue() expected 20, got " + tostring(doubled))
  return ()
}

// Calling static from within instance method
let added = m.addToValue(5)
if (added != 15) {
  println("FAIL: m.addToValue(5) expected 15, got " + tostring(added))
  return ()
}

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
if (c.getCount() != 3) {
  println("FAIL: counter expected 3, got " + tostring(c.getCount()))
  return ()
}

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
if (stars != "*****") {
  println("FAIL: repeat expected '*****', got " + stars)
  return ()
}

let sh = StringHelper("ab")
let rep = sh.repeated(3)
if (rep != "ababab") {
  println("FAIL: repeated expected 'ababab', got " + rep)
  return ()
}

println("PASS: 19_static_func")
