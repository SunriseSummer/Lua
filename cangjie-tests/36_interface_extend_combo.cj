dofile("cangjie-tests/_testing.cj")

// Comprehensive test: Interface + extend + default methods + operator overloading

// Interface with both abstract and default methods
interface Formattable {
    func format(): String
    func shortFormat(): String {
        return this.format()
    }
}

// Interface with operator defaults
interface Comparable {
    func compareTo(other: Comparable): Int64
    operator func <(other: Comparable): Bool {
        this.compareTo(other) < 0
    }
    operator func ==(other: Comparable): Bool {
        this.compareTo(other) == 0
    }
}

// Class implementing multiple interfaces
class Score <: Formattable & Comparable {
    Score(let value: Int64) {}
    func format(): String {
        return "Score(${value})"
    }
    func compareTo(other: Comparable): Int64 {
        return value - other.value
    }
}

let s1 = Score(85)
let s2 = Score(90)
let s3 = Score(85)

// Test abstract method
expectEq(s1.format(), "Score(85)", "s1.format()")

// Test default method
expectEq(s1.shortFormat(), "Score(85)", "s1.shortFormat() default")

// Test default operator <
expectTrue(s1 < s2, "85 < 90")
expectFalse(s2 < s1, "90 < 85 false")

// Test default operator ==
expectTrue(s1 == s3, "85 == 85")
expectFalse(s1 == s2, "85 == 90 false")

// Extend with interface default methods
interface Repeatable {
    func repeat(n: Int64): String {
        var result = ""
        var i = 0
        while (i < n) {
            result = result .. this.format()
            i += 1
        }
        return result
    }
    func format(): String
}

class Tag <: Repeatable {
    Tag(let name: String) {}
    func format(): String {
        return "[${name}]"
    }
}

let tag = Tag("A")
expectEq(tag.format(), "[A]", "tag.format()")
expectEq(tag.repeat(3), "[A][A][A]", "tag.repeat(3)")

// Interface with extend on built-in type
interface Stringifiable {
    func stringify(): String {
        return tostring(this)
    }
}

extend Int64 <: Stringifiable {
    func double(): Int64 { return this * 2 }
}

let n = 42
expectEq(n.double(), 84, "42.double()")

if (!__test_failed) {
    println("PASS: 36_interface_extend_combo")
}
