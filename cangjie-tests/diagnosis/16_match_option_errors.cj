dofile("cangjie-tests/_testing.cj")

// Diagnosis: Match pattern and Option type error detection

// --- Section: Match with invalid pattern syntax (load errors) ---
expectLoadError("invalid pattern in match case",
    "match (1) { case => println(\"x\") }",
    "invalid pattern in match expression")

expectLoadError("invalid pattern character in match",
    "match (1) { case @ => println(\"x\") }",
    "invalid pattern in match expression")

// --- Section: Option getOrThrow on None (runtime error) ---
expectRuntimeError("getOrThrow on None Int64",
    "var o: ?Int64 = None\no.getOrThrow()",
    "Option is None")

// --- Section: Match on non-existent enum constructor ---
// Undefined names resolve to nil; match falls through to wildcard
expectNoError("match with undefined name falls through to wildcard",
    "enum Color { Red | Green | Blue }\nmatch (Red) {\n  case Yellow => println(\"yellow\")\n  case _ => println(\"other\")\n}")

// --- Section: Duplicate case patterns (no error, first match wins) ---
expectNoError("duplicate case patterns compile and first wins",
    "match (1) {\n  case 1 => println(\"a\")\n  case 1 => println(\"b\")\n  case _ => println(\"c\")\n}")

// --- Section: Missing arrow in match case (load error) ---
expectLoadError("missing arrow in match case",
    "match (1) { case 1 println(\"x\") }",
    "'=>' expected")

// --- Section: Valid match with wildcard at end (no error) ---
expectNoError("valid match with wildcard",
    "let x = 5\nmatch (x) {\n  case 1 => println(\"one\")\n  case _ => println(\"other\")\n}")

// --- Section: Valid match expression returning value (no error) ---
expectNoError("match expression returns value",
    "let v = match (2) {\n  case 1 => \"one\"\n  case 2 => \"two\"\n  case _ => \"other\"\n}\nprintln(v)")

if (!__test_failed) {
    println("PASS: 16_match_option_errors")
}
