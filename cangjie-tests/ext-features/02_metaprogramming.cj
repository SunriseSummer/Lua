dofile("cangjie-tests/_testing.cj")

// Test: Lua metaprogramming (metatables and pcall)
// Demonstrates Lua's metatable capabilities extending Cangjie types.

// -- Section: metatable-based Vector type --
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
expectEq(tostring(v3), "Vector(4, 6)", "metatable __add")
expectEq(v3.x, 4, "v3.x")
expectEq(v3.y, 6, "v3.y")

// -- Section: pcall for error handling --
let ok, err = pcall(func() {
  error("test error")
})
expectFalse(ok, "pcall catches error")
expectTrue(string.find(tostring(err), "test error", 1, true) != nil, "pcall error message")

if (!__test_failed) {
    println("PASS: ext-features/02_metaprogramming")
}
