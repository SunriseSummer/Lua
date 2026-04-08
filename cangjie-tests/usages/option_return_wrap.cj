dofile("cangjie-tests/_testing.cj")

// Usage: Option return auto-wrapping with parseInt-style logic

func parseInt(text: String): ?Int64 {
    if (text.isEmpty() || text == "-") {
        return None
    }
    var sign = if (Int64(text[0]) == 45) { 1 } else { 0 }
    var sum = 0
    for (i in sign..text.size) {
        let code = Int64(text[i])
        if (code > 57 || code < 48) {
            return None
        }
        let digit = code - 48
        sum = 10 * sum + digit
    }
    return if (sign == 1) { -sum } else { sum }
}

let number = parseInt("-123456")
expectEq(number.getOrDefault(0), -123456, "parseInt negative value")

let result = parseInt("123-456")
expectTrue(result.isNone(), "parseInt invalid returns None")

let num = parseInt("123456")
var matched = false
if (let Some(value) <- num) {
    matched = true
    expectEq(value, 123456, "parseInt Some value")
}
expectTrue(matched, "parseInt returns Some for valid input")

expectTrue(parseInt("").isNone(), "parseInt empty returns None")
expectTrue(parseInt("-").isNone(), "parseInt lone minus returns None")

func passthroughOpt(v: ?Int64): ?Int64 {
    return v
}

let wrapped = passthroughOpt(Some(7))
expectEq(wrapped.getOrThrow(), 7, "Option return passes through Some")
expectTrue(passthroughOpt(None).isNone(), "Option return passes through None")

if (!__test_failed) {
    println("PASS: usages/option_return_wrap")
}
