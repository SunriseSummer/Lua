dofile("cangjie-tests/_testing.cj")

// Usage: Finite state machine number parser
// Demonstrates: class, 2D array, slice assignment, Int64 code point conversion,
//               string indexing, while loops, chained array indexing with expressions

class Parser {
    let states = Array(5, {i: Int64 => Array(128, 0)})

    init() {
        // State transition table indexed by ASCII code
        // Columns: '-'(45), '.'(46), '/'(47), '0'-'9'(48-57)
        states[0][45..58] = [1, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // INIT
        states[1][45..58] = [0, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // MINUS
        states[2][45..58] = [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] // DOT
        states[3][45..58] = [0, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // INTEGER
        states[4][45..58] = [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] // DECIMAL
    }

    func parse(text: String): String {
        var result = ""
        var i = 0
        while (i < text.size) {
            var s = 0
            while (i < text.size && states[s][Int64(text[i])] == 0) {
                i = i + 1
            }
            let j = i
            while (i < text.size && states[s][Int64(text[i])] != 0) {
                s = states[s][Int64(text[i])]
                i = i + 1
            }
            if (s == 3 || s == 4) {
                if (result.size > 0) {
                    result = result + " "
                }
                result = result + text[j..i]
            }
        }
        return result
    }
}

let p = Parser()

// --- Test: Simple integers ---
expectEq(p.parse("1 2 3 456 789"), "1 2 3 456 789", "simple integers")

// --- Test: Numbers mixed with letters ---
expectEq(p.parse("1ab2c3"), "1 2 3", "numbers in letters")

// --- Test: Numbers in words ---
expectEq(p.parse("apple 30 banana 45"), "30 45", "numbers in words")

// --- Test: Decimal numbers ---
expectEq(p.parse("1.2 3.4"), "1.2 3.4", "decimal numbers")

// --- Test: Negative numbers ---
expectEq(p.parse("9- -3 -2"), "9 -3 -2", "negative numbers")

// --- Test: Minus as separator ---
expectEq(p.parse("3-2"), "3 -2", "minus separator")

// --- Test: Sequence with separator ---
expectEq(p.parse("1 2 3-2"), "1 2 3 -2", "sequence with separator")

// --- Test: Mixed complex input ---
expectEq(p.parse("xxx-3.14. .56-238jk12"), "-3.14 .56 -238 12", "complex mixed")

// --- Test: Edge cases ---
expectEq(p.parse(""), "", "empty input")
expectEq(p.parse("abcdef"), "", "no numbers")
expectEq(p.parse("0"), "0", "single zero")
expectEq(p.parse("-"), "", "lone minus")
expectEq(p.parse("."), "", "lone dot")
expectEq(p.parse("-."), "", "minus-dot")
expectEq(p.parse(".5"), ".5", "leading dot decimal")
expectEq(p.parse("-5"), "-5", "negative number")
expectEq(p.parse("--5"), "-5", "double minus")

if (!__test_failed) {
    println("PASS: usages/number_parser")
}
