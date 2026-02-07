// Test: Bool default parameter values
// Verifies that passing 'false' is not confused with omitting the parameter

func check(flag!: Bool = true): Bool {
  return flag
}

// Explicit false should NOT use default
if (check(false) != false) {
  println("FAIL: check(false) expected false, got " + tostring(check(false)))
  return ()
}

// Explicit true should return true
if (check(true) != true) {
  println("FAIL: check(true) expected true, got " + tostring(check(true)))
  return ()
}

// Omitted should use default (true)
if (check() != true) {
  println("FAIL: check() expected true, got " + tostring(check()))
  return ()
}

// Multiple parameters with Bool defaults
func config(verbose!: Bool = false, debug!: Bool = false, strict!: Bool = true): String {
  var result = ""
  if (verbose) {
    result = result + "V"
  }
  if (debug) {
    result = result + "D"
  }
  if (strict) {
    result = result + "S"
  }
  return result
}

// All defaults: verbose=false, debug=false, strict=true
if (config() != "S") {
  println("FAIL: config() expected 'S', got '" + config() + "'")
  return ()
}

// Override verbose to true
if (config(true) != "VS") {
  println("FAIL: config(true) expected 'VS', got '" + config(true) + "'")
  return ()
}

// Override verbose=true, debug=true
if (config(true, true) != "VDS") {
  println("FAIL: config(true, true) expected 'VDS', got '" + config(true, true) + "'")
  return ()
}

// Override verbose=false, debug=false, strict=false
if (config(false, false, false) != "") {
  println("FAIL: config(false, false, false) expected '', got '" + config(false, false, false) + "'")
  return ()
}

// Override strict to false explicitly
if (config(false, false, false) != "") {
  println("FAIL: config with all false expected '', got '" + config(false, false, false) + "'")
  return ()
}

// Mix of types with Bool
func greet(name: String, excited!: Bool = false): String {
  if (excited) {
    return "Hello, " + name + "!!!"
  }
  return "Hello, " + name + "."
}

if (greet("World") != "Hello, World.") {
  println("FAIL: greet('World') expected 'Hello, World.', got '" + greet("World") + "'")
  return ()
}

if (greet("World", true) != "Hello, World!!!") {
  println("FAIL: greet('World', true) expected 'Hello, World!!!', got '" + greet("World", true) + "'")
  return ()
}

if (greet("World", false) != "Hello, World.") {
  println("FAIL: greet('World', false) expected 'Hello, World.', got '" + greet("World", false) + "'")
  return ()
}

// Int64 default (should still work correctly)
func power(base: Int64, exp!: Int64 = 2): Int64 {
  var result = 1
  var i = 0
  while (i < exp) {
    result = result * base
    i = i + 1
  }
  return result
}

if (power(3) != 9) {
  println("FAIL: power(3) expected 9, got " + tostring(power(3)))
  return ()
}

if (power(3, 3) != 27) {
  println("FAIL: power(3, 3) expected 27, got " + tostring(power(3, 3)))
  return ()
}

if (power(5, 0) != 1) {
  println("FAIL: power(5, 0) expected 1, got " + tostring(power(5, 0)))
  return ()
}

println("PASS: 21_bool_default_params")
