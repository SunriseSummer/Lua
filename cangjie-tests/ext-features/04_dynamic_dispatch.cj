// Extended features: Dynamic dispatch and runtime type flexibility
// These leverage Lua's dynamic nature combined with Cangjie's new features

// === Dynamic enum extension: adding methods at runtime ===
enum Option {
  | Some(Int64)
  | None
}

// Lua-style dynamic function to work with enum values
func unwrap_or(opt, default_val) {
  match (opt) {
    case Some(v) => { return v }
    case None => { return default_val }
  }
  return default_val
}

func map_option(opt, fn) {
  match (opt) {
    case Some(v) => { return Option.Some(fn(v)) }
    case None => { return Option.None }
  }
  return Option.None
}

let x = Option.Some(10)
let y = Option.None

println("unwrap Some: " .. tostring(unwrap_or(x, 0)))
println("unwrap None: " .. tostring(unwrap_or(y, -1)))

let doubled = map_option(x, func(v) { return v * 2 })
println("mapped: " .. tostring(unwrap_or(doubled, 0)))

// === Dynamic class construction with inheritance ===
class Base {
  var data: String
  init(data: String) {
    this.data = data
  }
  func process(): String {
    return this.data
  }
}

class Child <: Base {
  init(data: String) {
    this.data = "[" .. data .. "]"
  }
}

// Dynamic polymorphism: function accepting any object
func processAny(obj) {
  if (type(obj) == "table" and obj.process) {
    return obj.process()
  }
  return tostring(obj)
}

println(processAny(Base("raw")))
println(processAny(Child("wrapped")))
println(processAny(42))

// === Tuples with dynamic operations ===
func swap(t) {
  return (t[1], t[0])
}

let pair = (1, 2)
let swapped = swap(pair)
println("original: " .. tostring(pair[0]) .. "," .. tostring(pair[1]))
println("swapped: " .. tostring(swapped[0]) .. "," .. tostring(swapped[1]))

// === Using pcall with match for error handling ===
func safeDivide(a, b) {
  if (b == 0) {
    return Option.None
  }
  return Option.Some(a / b)
}

let r1 = safeDivide(10, 3)
let r2 = safeDivide(10, 0)

match (r1) {
  case Some(v) => { println("10/3 = " .. tostring(v)) }
  case None => { println("division by zero") }
}

match (r2) {
  case Some(v) => { println("10/0 = " .. tostring(v)) }
  case None => { println("division by zero") }
}

println("PASS: ext-features/04_dynamic_dispatch")
