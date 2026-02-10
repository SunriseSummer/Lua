dofile("cangjie-tests/_testing.cj")

// Test: Rune type boundary cases and edge conditions
// Validates native TValue-based Rune implementation

// -- Section: Rune type identity --
expectEq(type(r'a'), "Rune", "type(r'a') is Rune")
expectEq(type(r'\n'), "Rune", "type(r'\\n') is Rune")
expectEq(type(r'\u{0}'), "Rune", "type(r'\\u{0}') is Rune (NUL)")
expectEq(type(Rune(65)), "Rune", "type(Rune(65)) is Rune")
expectEq(type(Rune("A")), "Rune", "type(Rune(\"A\")) is Rune")

// -- Section: Explicit conversion needed for Int64 comparisons --
expectEq(Int64(r'A'), 65, "Int64(r'A') == 65")
expectFalse(r'A' == "A", "r'A' != \"A\" (Rune != String)")
expectEq(Int64(Rune(65)), 65, "Int64(Rune(65)) == 65")
expectFalse(Rune(65) == "A", "Rune(65) != \"A\"")

// -- Section: Boundary code points --

// NUL character (U+0000)
let nul: Rune = r'\u{0}'
expectEq(Int64(nul), 0, "Int64(r'\\u{0}') == 0")

// Maximum ASCII (U+007F)
let maxAscii = Rune(0x7F)
expectEq(Int64(maxAscii), 127, "Int64(Rune(0x7F)) == 127")

// First 2-byte UTF-8 (U+0080)
let first2byte = Rune(0x80)
expectEq(Int64(first2byte), 128, "Int64(Rune(0x80)) == 128")

// Maximum 2-byte UTF-8 (U+07FF)
let max2byte = Rune(0x7FF)
expectEq(Int64(max2byte), 0x7FF, "Int64(Rune(0x7FF)) == 0x7FF")

// First 3-byte UTF-8 (U+0800)
let first3byte = Rune(0x800)
expectEq(Int64(first3byte), 0x800, "Int64(Rune(0x800)) == 0x800")

// Maximum BMP (U+FFFF)
let maxBMP = Rune(0xFFFF)
expectEq(Int64(maxBMP), 0xFFFF, "Int64(Rune(0xFFFF)) == 0xFFFF")

// First 4-byte UTF-8 (U+10000) - supplementary plane
let first4byte = Rune(0x10000)
expectEq(Int64(first4byte), 0x10000, "Int64(Rune(0x10000)) == 0x10000")

// Maximum Unicode (U+10FFFF)
let maxUnicode = Rune(0x10FFFF)
expectEq(Int64(maxUnicode), 0x10FFFF, "Int64(Rune(0x10FFFF)) == 0x10FFFF")

// -- Section: Rune equality (same code points) --
expectTrue(Rune(65) == r'A', "Rune(65) == r'A'")
expectTrue(Rune("A") == r'A', "Rune(\"A\") == r'A'")
expectTrue(Rune(Rune(65)) == r'A', "Rune(Rune(65)) == r'A'")
expectTrue(r'a' == r'a', "r'a' == r'a' self-equality")

// -- Section: Rune ordering boundary --
expectTrue(r'\u{0}' < r'\u{1}', "U+0000 < U+0001")
expectTrue(r'A' < r'B', "r'A' < r'B'")
expectTrue(r'Z' < r'a', "r'Z' < r'a' (uppercase < lowercase)")
expectTrue(r'z' < r'\u{80}', "ASCII < non-ASCII")
expectTrue(Rune(0xFFFF) < Rune(0x10000), "BMP max < supplementary min")
expectFalse(r'b' < r'a', "r'b' not < r'a'")
expectTrue(r'a' <= r'a', "r'a' <= r'a' (equal)")
expectTrue(r'a' <= r'b', "r'a' <= r'b'")
expectFalse(r'b' <= r'a', "r'b' not <= r'a'")

// -- Section: Rune in conditional (truthy) --
let rval: Rune = r'X'
if (rval) {
    expectTrue(true, "Rune is truthy in condition")
} else {
    expectTrue(false, "Rune should be truthy")
}

// -- Section: Rune to String conversion edge cases --
expectEq(String(r'\u{0}'), "\u{0}", "String of NUL rune")
expectEq(String(Rune(0x24)), "$", "String(Rune(0x24)) == '$'")
expectEq(String(Rune(0x20AC)), "€", "String(Rune(0x20AC)) == '€'")

// -- Section: Rune in string concatenation via interpolation --
let r1: Rune = r'H'
let r2: Rune = r'i'
let greeting = "${r1}${r2}"
expectEq(greeting, "Hi", "Rune interpolation produces string")

// -- Section: Rune in tostring --
expectEq(tostring(r'A'), "A", "tostring(r'A') == 'A'")
expectEq(tostring(r'好'), "好", "tostring(r'好') == '好'")
expectEq(tostring(Rune(0x1F600)), "😀", "tostring emoji rune")

// -- Section: Rune identity through Rune() constructor --
let orig: Rune = r'X'
let copy = Rune(orig)
expectTrue(orig == copy, "Rune(rune) preserves equality")
expectEq(Int64(orig), Int64(copy), "Rune(rune) preserves code point")

// -- Section: Rune comparison with different construction methods --
let byLiteral = r'A'
let byInt = Rune(65)
let byStr = Rune("A")
let byNested = Rune(Rune(65))
expectTrue(byLiteral == byInt, "literal == from int")
expectTrue(byLiteral == byStr, "literal == from string")
expectTrue(byLiteral == byNested, "literal == from nested")
expectTrue(byInt == byStr, "from int == from string")

// -- Section: Rune variable assignment and reassignment --
var mutable: Rune = r'a'
expectEq(Int64(mutable), 97, "initial Rune value")
mutable = r'b'
expectEq(Int64(mutable), 98, "reassigned Rune value")
mutable = Rune(99)
expectEq(Int64(mutable), 99, "reassigned via Rune()")

// -- Section: Rune in array --
let runes = [r'a', r'b', r'c']
expectEq(runes.size, 3, "Rune array size")
expectEq(runes[0], r'a', "Rune array element 0")
expectEq(runes[1], r'b', "Rune array element 1")
expectEq(runes[2], r'c', "Rune array element 2")

// -- Section: Rune passed to/from function --
func runeIdentity(r: Rune): Rune {
    return r
}
expectEq(runeIdentity(r'Z'), r'Z', "Rune function pass-through")
expectEq(Int64(runeIdentity(Rune(0x4E2D))), 0x4E2D, "Rune function with CJK")

// -- Section: Rune in match/comparison chain --
let testRune: Rune = r'B'
var matched = ""
if (testRune == r'A') {
    matched = "A"
} else if (testRune == r'B') {
    matched = "B"
} else {
    matched = "other"
}
expectEq(matched, "B", "Rune in if-else chain")

if (!__test_failed) {
    println("PASS: 79_rune_boundary")
}
