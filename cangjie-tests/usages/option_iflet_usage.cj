dofile("cangjie-tests/_testing.cj")

// Test: Option + if-let/while-let + auto-constructor + Array

// -- Section: auto-constructor class with Option fields --
class Config {
  var name: String = ""
  var maxRetries: Int64 = 0
}

func findConfig(name: String): ?Config {
  if (name == "prod") {
    return Some(Config("production", 5))
  }
  if (name == "dev") {
    return Some(Config("development", 1))
  }
  return None
}

// -- Section: if-let basic usage --
var iflet_result = ""
if (let Some(cfg) <- findConfig("prod")) {
  iflet_result = cfg.name
}
expectEq(iflet_result, "production", "if-let prod")

// -- Section: if-let with && condition --
var iflet_and = false
if (let Some(cfg) <- findConfig("prod") && cfg.maxRetries > 3) {
  iflet_and = true
}
expectTrue(iflet_and, "if-let && retries > 3")

// -- Section: if-let with || fallback --
var useFallback = true
var iflet_or = false
if (let Some(cfg) <- findConfig("unknown") || useFallback) {
  iflet_or = true
}
expectTrue(iflet_or, "if-let || fallback")

// -- Section: nested if-let --
var nested_result = ""
if (let Some(cfg) <- findConfig("dev")) {
  if (let Some(prod) <- findConfig("prod")) {
    nested_result = cfg.name + " and " + prod.name
  }
}
expectEq(nested_result, "development and production", "nested if-let")

// -- Section: coalescing with default --
let maybeConfig = findConfig("unknown")
let cfg = maybeConfig ?? Config("default", 0)
expectEq(cfg.name, "default", "coalesce default")

// -- Section: array of Options --
let results = [findConfig("prod"), findConfig("unknown"), findConfig("dev")]
var found_names = ""
var none_count = 0
var i = 0
while (i < results.size) {
  if (let Some(c) <- results[i]) {
    found_names = found_names + c.name + " "
  } else {
    none_count = none_count + 1
  }
  i = i + 1
}
expectEq(found_names, "production development ", "array of Options names")
expectEq(none_count, 1, "array of Options none count")

// -- Section: while-let with generator --
var attempts = 3
func tryConnect(): ?String {
  if (attempts > 0) {
    attempts = attempts - 1
    return Some("connection_${attempts}")
  }
  return None
}

var connections = ""
while (let Some(conn) <- tryConnect()) {
  connections = connections + conn + " "
}
expectEq(connections, "connection_2 connection_1 connection_0 ", "while-let connections")

// -- Section: Option method usage --
let val = Some(100)
expectTrue(val.isSome(), "Some isSome")
expectEq(val.getOrThrow(), 100, "Some getOrThrow")
expectEq(val.getOrDefault({ => 0 }), 100, "Some getOrDefault")

let empty = None
expectFalse(empty.isSome(), "None isSome")
expectEq(empty.getOrDefault({ => -1 }), -1, "None getOrDefault")

// -- Section: match on Option --
var match_result = ""
match (findConfig("prod")) {
  case Some(c) =>
    match_result = c.name
  case None =>
    match_result = "no config"
}
expectEq(match_result, "production", "match Option prod")

if (!__test_failed) {
    println("PASS: usages/option_iflet_usage")
}
