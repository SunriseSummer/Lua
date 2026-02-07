// Comprehensive usage: Option + if-let/while-let + auto-constructor + Array

// Auto-constructor class with Option fields
class Config {
  var name: String = ""
  var maxRetries: Int64 = 0
}

// Function returning Option
func findConfig(name: String): ?Config {
  if (name == "prod") {
    return Some(Config("production", 5))
  }
  if (name == "dev") {
    return Some(Config("development", 1))
  }
  return None
}

// if-let basic usage
if (let Some(cfg) <- findConfig("prod")) {
  println("found: ${cfg.name}, retries: ${cfg.maxRetries}")
}

// if-let with && condition using bound variable
if (let Some(cfg) <- findConfig("prod") && cfg.maxRetries > 3) {
  println("prod retries > 3: true")
}

// if-let with || fallback condition
var useFallback = true
if (let Some(cfg) <- findConfig("unknown") || useFallback) {
  println("fallback triggered")
}

// Nested if-let
if (let Some(cfg) <- findConfig("dev")) {
  println("dev found: ${cfg.name}")
  if (let Some(prod) <- findConfig("prod")) {
    println("both exist: ${cfg.name} and ${prod.name}")
  }
}

// Coalescing with default
let maybeConfig = findConfig("unknown")
let cfg = maybeConfig ?? Config("default", 0)
println("coalesce: ${cfg.name}")

// Array of Options
let results = [findConfig("prod"), findConfig("unknown"), findConfig("dev")]
var i = 0
while (i < results.size) {
  if (let Some(c) <- results[i]) {
    println("result[${i}]: ${c.name}")
  } else {
    println("result[${i}]: None")
  }
  i = i + 1
}

// while-let with a generator
var attempts = 3
func tryConnect(): ?String {
  if (attempts > 0) {
    attempts = attempts - 1
    return Some("connection_${attempts}")
  }
  return None
}

while (let Some(conn) <- tryConnect()) {
  println("connected: ${conn}")
}
println("no more connections")

// Option method usage
let val = Some(100)
println("isSome: ${val.isSome()}")
println("getOrThrow: ${val.getOrThrow()}")
println("getOrDefault: ${val.getOrDefault({ => 0 })}")

let empty = None
println("empty isSome: ${empty.isSome()}")
println("empty getOrDefault: ${empty.getOrDefault({ => -1 })}")

// Match on Option
match (findConfig("prod")) {
  case Some(c) =>
    println("matched config: ${c.name}")
  case None =>
    println("no config")
}

println("PASS: option_iflet_usage")
