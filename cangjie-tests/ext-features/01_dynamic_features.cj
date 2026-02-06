// Extended features: Lua dynamic capabilities
// These features go beyond standard Cangjie syntax,
// leveraging Lua's dynamic nature for enhanced flexibility.

// nil value (Lua's null) - Cangjie uses Unit
let z = nil
println(z)      // nil

// Multiple assignment (Lua feature)
let m, n = 100, 200
println(m)      // 100
println(n)      // 200

// Multiple return values from functions
func divmod(a: Int64, b: Int64) {
  return a / b, a % b
}
let q, r = divmod(17, 5)
println("17 / 5 = ${q}, remainder ${r}")

// Dynamic typing - same variable can hold any type
var dyn = 42
println("int: ${dyn}")
dyn = "hello"
println("string: ${dyn}")
dyn = true
println("bool: ${dyn}")

// Table as associative array (Lua feature)
let dict = {}
dict["name"] = "Cangjie"
dict["version"] = 1
dict[42] = "answer"
println(dict["name"])
println(dict[42])

// # operator for raw table length
let raw = {10, 20, 30}
println(#raw)  // 3

// ipairs iterator
print("ipairs: ")
for (k, v in ipairs(raw)) {
  print("${k}=${v} ")
}
println()

// pairs iterator for all keys
print("pairs: ")
for (k, v in pairs(dict)) {
  print(tostring(k) .. "=" .. tostring(v) .. " ")
}
println()

println("PASS: ext-features/01_dynamic_features")
