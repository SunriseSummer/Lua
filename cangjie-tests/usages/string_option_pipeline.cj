dofile("cangjie-tests/_testing.cj")

// Usage: Combine string methods, arrays, for-in loops, and Option defaults

let raw = [" apple ", "banana", "", " Cherry "]
var cleaned: Array<String> = []
var count = 0
var first: ?String = None
var summary = ""

for (name in raw) {
    let trimmed = name.trim()
    if (trimmed.size > 0) {
        let upper = trimmed.toAsciiUpper()
        cleaned[count] = upper
        if (first.isNone()) {
            first = Some(upper)
        }
        if (summary.size > 0) {
            summary = summary + ","
        }
        summary = summary + upper
        count = count + 1
    }
}

expectEq(count, 3, "normalized count")
expectEq(cleaned[0], "APPLE", "first cleaned entry")
expectEq(cleaned[2], "CHERRY", "last cleaned entry")
expectEq(summary, "APPLE,BANANA,CHERRY", "summary join")

let firstName = first ?? "NONE"
expectEq(firstName, "APPLE", "option coalesce for first name")
let missing: ?String = None
expectEq(missing ?? "NONE", "NONE", "coalesce fallback for missing")

if (!__test_failed) {
    println("PASS: usages/string_option_pipeline")
}
