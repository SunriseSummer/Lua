dofile("cangjie-tests/_testing.cj")

// Diagnosis: Advanced error detection — inheritance errors, Option misuse,
// match errors, and type conversion edge cases

// --- Section: super() without parent class ---
expectRuntimeError("super without parent",
    'class Orphan { func init() { __cangjie_super_init(self, Orphan) } }; Orphan()',
    "class has no parent")

// --- Section: getOrThrow on None ---
expectRuntimeError("getOrThrow on None",
    'let n = None; n.getOrThrow()',
    "Option is None")

// --- Section: Invalid Rune conversion - empty string ---
expectRuntimeError("Rune empty string",
    'Rune("")',
    "cannot convert empty string")

// --- Section: Invalid Rune conversion - multi-char string ---
expectRuntimeError("Rune multi-char string",
    'Rune("abc")',
    "single-character string")

// --- Section: Invalid Int64 conversion - non-numeric string ---
expectRuntimeError("Int64 non-numeric",
    'Int64("hello")',
    "cannot convert string")

// --- Section: Invalid Int64 conversion - empty string ---
expectRuntimeError("Int64 empty string",
    'Int64("")',
    "cannot convert empty string")

// --- Section: Bool conversion from invalid string ---
expectRuntimeError("Bool invalid string",
    'Bool("yes")',
    "cannot convert string")

// --- Section: Float64 conversion from invalid string ---
expectRuntimeError("Float64 invalid string",
    'Float64("not-a-number")',
    "cannot convert string")

// --- Section: String immutability ---
expectRuntimeError("string immutable",
    'let s = "hello"; s[0] = "H"',
    "immutable")

// --- Section: String index out of range ---
expectRuntimeError("string index negative",
    'let s = "hi"; let _ = s[-1]',
    "out of range")

expectRuntimeError("string index too large",
    'let s = "hi"; let _ = s[5]',
    "out of range")

// --- Section: Array size must be non-negative ---
expectRuntimeError("array negative size",
    'let a = Array(-1, 0)',
    "non-negative")

// --- Section: Iterate over nil ---
expectRuntimeError("iterate nil",
    'for (x in nil) { println(x) }',
    "cannot iterate")

// --- Section: Load errors - syntax ---
expectLoadError("missing closing brace",
    'func f() { let x = 1',
    "expected")

expectLoadError("invalid assignment target",
    '42 = 10',
    "syntax error")

// --- Section: Compile-time errors ---
expectLoadError("let without value",
    'let x',
    "requires an initializer")

// --- Section: Redefining let variable ---
expectLoadError("redefine let",
    'let x = 1; let x = 2',
    "already defined")

if (!__test_failed) {
    println("PASS: 17_advanced_runtime_errors")
}
