dofile("cangjie-tests/_testing.cj")

// Usage: Rune type in practical string/character processing scenarios

// -- Scenario 1: Character classification --
func isAsciiDigit(r: Rune): Bool {
    return r >= r'0' && r <= r'9'
}

func isAsciiAlpha(r: Rune): Bool {
    return (r >= r'a' && r <= r'z') || (r >= r'A' && r <= r'Z')
}

func isAsciiUpper(r: Rune): Bool {
    return r >= r'A' && r <= r'Z'
}

func isAsciiLower(r: Rune): Bool {
    return r >= r'a' && r <= r'z'
}

expectTrue(isAsciiDigit(r'0'), "isDigit '0'")
expectTrue(isAsciiDigit(r'9'), "isDigit '9'")
expectFalse(isAsciiDigit(r'a'), "isDigit 'a'")
expectTrue(isAsciiAlpha(r'A'), "isAlpha 'A'")
expectTrue(isAsciiAlpha(r'z'), "isAlpha 'z'")
expectFalse(isAsciiAlpha(r'1'), "isAlpha '1'")
expectTrue(isAsciiUpper(r'M'), "isUpper 'M'")
expectFalse(isAsciiUpper(r'm'), "isUpper 'm'")
expectTrue(isAsciiLower(r'q'), "isLower 'q'")
expectFalse(isAsciiLower(r'Q'), "isLower 'Q'")

// -- Scenario 2: Simple Caesar cipher with Rune --
func caesarEncrypt(r: Rune, shift: Int64): Rune {
    if (isAsciiUpper(r)) {
        let ubase = Int64(r'A')
        let shifted = (Int64(r) - ubase + shift) % 26
        return Rune(ubase + shifted)
    } else if (isAsciiLower(r)) {
        let lbase = Int64(r'a')
        let shifted2 = (Int64(r) - lbase + shift) % 26
        return Rune(lbase + shifted2)
    }
    return r
}

expectEq(caesarEncrypt(r'A', 3), r'D', "Caesar A+3 = D")
expectEq(caesarEncrypt(r'Z', 1), r'A', "Caesar Z+1 = A (wrap)")
expectEq(caesarEncrypt(r'a', 13), r'n', "Caesar a+13 = n (ROT13)")
expectEq(caesarEncrypt(r'1', 5), r'1', "Caesar digit unchanged")

// -- Scenario 3: Rune array from string and processing --
let word = "Hello"
var runes = Array<Rune>(word.size, r'\u{0}')
for (i in 0..word.size) {
    runes[i] = Rune(word[i])
}
expectEq(runes.size, 5, "Rune array from string size")
expectEq(runes[0], r'H', "Rune array [0]")
expectEq(runes[4], r'o', "Rune array [4]")

// Reconstruct string from runes
var rebuilt = ""
for (i in 0..runes.size) {
    rebuilt = rebuilt + String(runes[i])
}
expectEq(rebuilt, "Hello", "String from Rune array")

// -- Scenario 4: Unicode Rune processing --
let chinese = "你好世界"
var codepoints = Array<Int64>(chinese.size, 0)
for (i in 0..chinese.size) {
    codepoints[i] = Int64(Rune(chinese[i]))
}
expectEq(codepoints.size, 4, "CJK string codepoints count")
expectEq(codepoints[0], 0x4F60, "你 codepoint")
expectEq(codepoints[1], 0x597D, "好 codepoint")
expectEq(codepoints[2], 0x4E16, "世 codepoint")
expectEq(codepoints[3], 0x754C, "界 codepoint")

// -- Scenario 5: Rune in data structure (class with Rune field) --
class CharInfo {
    let ch: Rune
    let pos: Int64
    init(ch: Rune, pos: Int64) {
        this.ch = ch
        this.pos = pos
    }
    func toString(): String {
        return "${this.ch}@${this.pos}"
    }
}

let info = CharInfo(r'X', 42)
expectEq(info.ch, r'X', "CharInfo Rune field")
expectEq(info.pos, 42, "CharInfo position")
expectEq(info.toString(), "X@42", "CharInfo toString with Rune interpolation")

// -- Scenario 6: Rune as function parameter and return --
func nextRune(r: Rune): Rune {
    return Rune(Int64(r) + 1)
}

func prevRune(r: Rune): Rune {
    return Rune(Int64(r) - 1)
}

expectEq(nextRune(r'A'), r'B', "nextRune A -> B")
expectEq(prevRune(r'B'), r'A', "prevRune B -> A")
expectEq(nextRune(r'Z'), r'[', "nextRune Z -> [")

// -- Scenario 7: Count specific Rune in string --
func countRune(s: String, target: Rune): Int64 {
    var count = 0
    for (i in 0..s.size) {
        if (Rune(s[i]) == target) {
            count = count + 1
        }
    }
    return count
}

expectEq(countRune("hello world", r'l'), 3, "count 'l' in 'hello world'")
expectEq(countRune("aabbcc", r'b'), 2, "count 'b' in 'aabbcc'")
expectEq(countRune("xyz", r'a'), 0, "count 'a' in 'xyz'")

// -- Scenario 8: Rune in closure --
func makeRuneCounter(): (Rune) -> Int64 {
    var count = 0
    return { r: Rune =>
        count = count + 1
        return count
    }
}

let counter = makeRuneCounter()
expectEq(counter(r'a'), 1, "Rune closure call 1")
expectEq(counter(r'b'), 2, "Rune closure call 2")
expectEq(counter(r'c'), 3, "Rune closure call 3")

if (!__test_failed) {
    println("PASS: rune_comprehensive_usage")
}
