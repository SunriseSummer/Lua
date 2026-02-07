// Built-in Option type
let a = Some(42)
let b = None

// Check tags
println(a.isSome())   // true
println(a.isNone())   // false
println(b.isSome())   // false
println(b.isNone())   // true

// getOrThrow
println(a.getOrThrow())  // 42

// getOrDefault (takes () -> T function)
println(a.getOrDefault({ => 0 }))  // 42
println(b.getOrDefault({ => 0 }))  // 0

// Pattern matching with Option
match (a) {
  case Some(v) => println("Some: ${v}")  // Some: 42
  case None => println("None")
}

match (b) {
  case Some(v) => println("Some: ${v}")
  case None => println("None")  // None
}

// Coalescing operator ??
let x = a ?? 0
println(x)  // 42 (unwrapped from Some)
let y = b ?? 99
println(y)  // 99 (default for None)

// ?Type in type annotations (just syntax, skipped)
let c: ?Int64 = Some(10)
let d: ?String = None
println(c.getOrThrow())  // 10

println("PASS: 26_option_type")
