dofile("cangjie-tests/_testing.cj")

// Usage: Finite state machine number parser
// Parses integer and decimal numbers (with optional sign) from text

class Parser {
    let states = Array(5, {i: Int64 => Array(128, 0)})
    init() {
        states[0][45..58] = [1, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // INIT
        states[1][45..58] = [0, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // -
        states[2][45..58] = [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] // . | -. | N. | -N.
        states[3][45..58] = [0, 2, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] // N or -N
        states[4][45..58] = [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] // ACCEPT
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

// Basic integers
expectEq(p.parse("1 2 3 456 789"), "1 2 3 456 789", "basic integers")

// Numbers mixed with letters
expectEq(p.parse("1ab2c3"), "1 2 3", "letters mix")

// Numbers among words
expectEq(p.parse("apple 30 banana 45"), "30 45", "words mix")

// Decimal numbers
expectEq(p.parse("1.2 3.4"), "1.2 3.4", "decimals")

// Negative numbers
expectEq(p.parse("9- -3 -2"), "9 -3 -2", "negative nums")

// Adjacent minus
expectEq(p.parse("3-2"), "3 -2", "adjacent minus")

// Mixed with spaces
expectEq(p.parse("1 2 3-2"), "1 2 3 -2", "mixed spaces")

// Complex mixed
expectEq(p.parse("xxx-3.14. .56-238jk12"), "-3.14 .56 -238 12", "complex mixed")

// Empty string
expectEq(p.parse(""), "", "empty string")

// No numbers
expectEq(p.parse("hello world"), "", "no numbers")

// Single number
expectEq(p.parse("42"), "42", "single number")

// Single negative
expectEq(p.parse("-7"), "-7", "single negative")

// Decimal without integer part
expectEq(p.parse(".5"), ".5", "decimal no int part")

if (!__test_failed) {
    println("PASS: usages/number_parser")
}
