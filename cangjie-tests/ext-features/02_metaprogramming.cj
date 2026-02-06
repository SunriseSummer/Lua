// Extended features: Lua metaprogramming
// Demonstrates Lua's metatable capabilities extending Cangjie types.

// Direct metatable manipulation using Lua : syntax
let Vector = {}
Vector.__index = Vector

Vector.init = func(self, x, y) {
  self.x = x
  self.y = y
  return self
}

Vector.__add = func(a, b) {
  return setmetatable({}, Vector):init(a.x + b.x, a.y + b.y)
}

Vector.__tostring = func(self) {
  return "Vector(${self.x}, ${self.y})"
}

let v1 = setmetatable({}, Vector):init(1, 2)
let v2 = setmetatable({}, Vector):init(3, 4)
let v3 = v1 + v2
println(tostring(v3))  // Vector(4, 6)

// pcall for error handling (Lua feature)
let ok, err = pcall(func() {
  error("test error")
})
println("pcall caught: ${tostring(err)}")

println("PASS: ext-features/02_metaprogramming")
