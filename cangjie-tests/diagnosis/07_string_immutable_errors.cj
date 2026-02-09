dofile("cangjie-tests/_testing.cj")

// Test: String and immutability error diagnostics

// --- Section: immutable variable error message ---
expectLoadError("let variable reassignment",
    "let x = 10\nx = 20",
    "attempt to assign to immutable variable")

expectLoadError("let string reassignment",
    "let s = \"hello\"\ns = \"world\"",
    "attempt to assign to immutable variable")

// --- Section: string index out of range ---
expectRuntimeError("string index negative",
    "let s = \"hello\"\nlet c = s[-1]",
    "out of range")

expectRuntimeError("string index too large",
    "let s = \"hello\"\nlet c = s[5]",
    "out of range")

expectRuntimeError("string index on empty",
    "let s = \"\"\nlet c = s[0]",
    "out of range")

// --- Section: string index assignment immutability (integer key) ---
expectRuntimeError("string newindex integer key",
    "let s = \"hello\"\ns[0] = \"H\"",
    "immutable")

expectRuntimeError("var string newindex integer key",
    'var s = "hello"\ns[0] = "H"',
    "immutable")

expectRuntimeError("string newindex middle index",
    'let s = "hello"\ns[2] = "X"',
    "immutable")

expectRuntimeError("string newindex last index",
    'let s = "hello"\ns[4] = "X"',
    "immutable")

// --- Section: string index assignment immutability (string key / dot notation) ---
expectRuntimeError("string newindex string key",
    'let s = "hello"\ns["x"] = 123',
    "immutable")

expectRuntimeError("string newindex dot notation",
    'let s = "hello"\ns.foo = 42',
    "immutable")

// --- Section: CJK string index assignment immutability ---
expectRuntimeError("CJK string newindex",
    'let s = "你好世界"\ns[0] = "我"',
    "immutable")

expectRuntimeError("CJK string newindex middle",
    'let s = "你好世界"\ns[2] = "地"',
    "immutable")

// --- Section: emoji string index assignment immutability ---
expectRuntimeError("emoji string newindex",
    'let s = "Hello😀"\ns[5] = "🎉"',
    "immutable")

// --- Section: string from operations remains immutable ---
expectRuntimeError("concatenated string immutable",
    'var s = "hello" + " " + "world"\ns[0] = "H"',
    "immutable")

expectRuntimeError("interpolated string immutable",
    "let name = \"world\"\nvar s = \"Hello \" + name\ns[0] = \"h\"",
    "immutable")

expectRuntimeError("slice result immutable",
    'let s = "hello"\nvar sub = s[0..3]\nsub[0] = "X"',
    "immutable")

expectRuntimeError("replace result immutable",
    'var s = "hello".replace("l", "r")\ns[0] = "H"',
    "immutable")

expectRuntimeError("upper result immutable",
    'var s = "hello".toAsciiUpper()\ns[0] = "h"',
    "immutable")

expectRuntimeError("split element immutable",
    'let parts = "a,b,c".split(",")\nparts[0][0] = "X"',
    "immutable")

expectRuntimeError("toRuneArray element immutable",
    'let runes = "hello".toRuneArray()\nrunes[0][0] = "X"',
    "immutable")

// --- Section: var still allows reassignment (but not index mutation) ---
expectNoError("var variable reassignment",
    "var x = 10\nx = 20")

expectNoError("var string reassignment",
    "var s = \"hello\"\ns = \"world\"")

// --- Section: valid string operations ---
expectNoError("string index valid",
    "let s = \"hello\"\nlet c = s[0]\nlet n = s.size")

expectNoError("string slice valid",
    "let s = \"hello\"\nlet sub = s[0..3]")

if (!__test_failed) {
    println("PASS: diagnosis/07_string_immutable_errors")
}
