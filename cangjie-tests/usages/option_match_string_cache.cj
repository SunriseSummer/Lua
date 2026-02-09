dofile("cangjie-tests/_testing.cj")

// Usage: combine Option, match expression, and UTF-8 string caching

func safeCharAt(s: String, idx: Int64): ?Rune {
    if (idx < 0 || idx >= s.size) {
        return None
    }
    return Some(s[idx])
}

func describeChar(s: String, idx: Int64): String {
    let cached = s.cacheIndex()
    return match (safeCharAt(cached, idx)) {
        case Some(ch) => "char:${String(ch)}"
        case None => "out"
    }
}

expectEq(describeChar("你好", 1), "char:好", "match Some with cached UTF-8")
expectEq(describeChar("hi", 5), "out", "match None for out-of-range index")
expectEq(describeChar("ab", 0), "char:a", "match Some for first char")

if (__test_failed) {
    println("FAIL: usages/option_match_string_cache")
} else {
    println("PASS: usages/option_match_string_cache")
}
