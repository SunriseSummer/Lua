dofile("cangjie-tests/_testing.cj")

// Test: Bool default parameter values
// Verifies that passing 'false' is not confused with omitting the parameter

func check(flag!: Bool = true): Bool {
  return flag
}

// Explicit false should NOT use default
expectFalse(check(false), "check(false)")

// Explicit true should return true
expectTrue(check(true), "check(true)")

// Omitted should use default (true)
expectTrue(check(), "check() default")

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
expectEq(config(), "S", "config() all defaults")

// Override verbose to true
expectEq(config(true), "VS", "config(true)")

// Override verbose=true, debug=true
expectEq(config(true, true), "VDS", "config(true, true)")

// Override verbose=false, debug=false, strict=false
expectEq(config(false, false, false), "", "config(false, false, false)")

// Override strict to false explicitly
expectEq(config(false, false, false), "", "config with all false")

// Mix of types with Bool
func greet(name: String, excited!: Bool = false): String {
  if (excited) {
    return "Hello, " + name + "!!!"
  }
  return "Hello, " + name + "."
}

expectEq(greet("World"), "Hello, World.", "greet('World')")
expectEq(greet("World", true), "Hello, World!!!", "greet('World', true)")
expectEq(greet("World", false), "Hello, World.", "greet('World', false)")

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

expectEq(power(3), 9, "power(3)")
expectEq(power(3, 3), 27, "power(3, 3)")
expectEq(power(5, 0), 1, "power(5, 0)")

if (!__test_failed) {
    println("PASS: 21_bool_default_params")
}
