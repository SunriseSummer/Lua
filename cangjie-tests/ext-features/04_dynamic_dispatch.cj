// Extended features: Dynamic dispatch, enum internals, and generic enums
// These leverage Lua's dynamic nature combined with Cangjie's new features

// === Dynamic enum: accessing internal representation (Lua extension) ===
// In standard Cangjie, enum values don't expose [1], [2] indexing.
// Here we can access the internal representation directly.
enum Color {
  | Red
  | Green
  | Blue(Int64)
  | RGB(Int64, Int64, Int64)
}

let r = Red
let b = Blue(128)
let rgb = RGB(255, 128, 0)

// Direct access to __tag (Lua extension)
println(r.__tag)     // Red
println(b.__tag)     // Blue
println(rgb.__tag)   // RGB

// Index-based access to enum constructor args (Lua extension)
println(b[1])        // 128
println(rgb[1])      // 255
println(rgb[2])      // 128
println(rgb[3])      // 0

// === Generic enum (type params erased, work via dynamic typing) ===
enum Option<T> {
  | Some(T)
  | None
}

// Lua-style dynamic function to work with enum values
func unwrap_or(opt, default_val) {
  match (opt) {
    case Some(v) =>
      return v
    case None =>
      return default_val
  }
  return default_val
}

func map_option(opt, fn) {
  match (opt) {
    case Some(v) =>
      return Some(fn(v))
    case None =>
      return None
  }
  return None
}

let x = Some(10)
let y = None

println("unwrap Some: " .. tostring(unwrap_or(x, 0)))
println("unwrap None: " .. tostring(unwrap_or(y, -1)))

let doubled = map_option(x, func(v) { return v * 2 })
println("mapped: " .. tostring(unwrap_or(doubled, 0)))

// Generic enum with different types (dynamic)
let str_opt = Some("hello")
println("string option: " .. tostring(unwrap_or(str_opt, "default")))

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
  if (type(obj) == "table" && obj.process) {
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

// === Match with braces (extended syntax for Lua compatibility) ===
let r1 = Some(10)
let r2 = None

match (r1) {
  case Some(v) =>
    println("10: " .. tostring(v))
  case None =>
    println("none")
}

match (r2) {
  case Some(v) =>
    println("value: " .. tostring(v))
  case None =>
    println("division by zero")
}

println("PASS: ext-features/04_dynamic_dispatch")
