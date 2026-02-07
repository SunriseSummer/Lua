dofile("cangjie-tests/_testing.cj")

// Test: Dynamic dispatch, enum internals, and generic enums
// These leverage Lua's dynamic nature combined with Cangjie's new features

// -- Section: dynamic enum internal representation --
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
expectEq(r.__tag, "Red", "Red __tag")
expectEq(b.__tag, "Blue", "Blue __tag")
expectEq(rgb.__tag, "RGB", "RGB __tag")

// Index-based access to enum constructor args (Lua extension)
expectEq(b[1], 128, "Blue[1]")
expectEq(rgb[1], 255, "RGB[1]")
expectEq(rgb[2], 128, "RGB[2]")
expectEq(rgb[3], 0, "RGB[3]")

// -- Section: generic enum (dynamic typing) --
enum Option<T> {
  | Some(T)
  | None
}

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

expectEq(unwrap_or(x, 0), 10, "unwrap Some")
expectEq(unwrap_or(y, -1), -1, "unwrap None")

let doubled = map_option(x, func(v) { return v * 2 })
expectEq(unwrap_or(doubled, 0), 20, "map_option doubled")

let str_opt = Some("hello")
expectEq(unwrap_or(str_opt, "default"), "hello", "string option unwrap")

// -- Section: dynamic class construction with inheritance --
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

func processAny(obj) {
  if (type(obj) == "table" && obj.process) {
    return obj.process()
  }
  return tostring(obj)
}

expectEq(processAny(Base("raw")), "raw", "processAny Base")
expectEq(processAny(Child("wrapped")), "[wrapped]", "processAny Child")
expectEq(processAny(42), "42", "processAny primitive")

// -- Section: tuples with dynamic operations --
func swap(t) {
  return (t[1], t[0])
}

let pair = (1, 2)
let swapped = swap(pair)
expectEq(pair[0], 1, "pair[0]")
expectEq(pair[1], 2, "pair[1]")
expectEq(swapped[0], 2, "swapped[0]")
expectEq(swapped[1], 1, "swapped[1]")

// -- Section: match with enum (extended syntax) --
let r1 = Some(10)
let r2 = None

var match_result1 = ""
match (r1) {
  case Some(v) =>
    match_result1 = tostring(v)
  case None =>
    match_result1 = "none"
}
expectEq(match_result1, "10", "match Some(10)")

var match_result2 = ""
match (r2) {
  case Some(v) =>
    match_result2 = "value: " .. tostring(v)
  case None =>
    match_result2 = "division by zero"
}
expectEq(match_result2, "division by zero", "match None")

if (!__test_failed) {
    println("PASS: ext-features/04_dynamic_dispatch")
}
