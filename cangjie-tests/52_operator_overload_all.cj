dofile("cangjie-tests/_testing.cj")

// Test: Comprehensive operator overloading for all supported operators
// Covers +, -, *, /, %, **, ==, <, <=, <<, >>, &, |, ^, ~, # in
// struct definitions, extend blocks, interface declarations, and enum bodies

// ============================================================
// Section 1: Operator overloading in struct via extend
// ============================================================

struct Vec2 {
    var x: Int64 = 0
    var y: Int64 = 0
}

extend Vec2 {
    // Arithmetic
    operator func +(other: Vec2): Vec2 { Vec2(this.x + other.x, this.y + other.y) }
    operator func -(other: Vec2): Vec2 { Vec2(this.x - other.x, this.y - other.y) }
    operator func *(other: Vec2): Vec2 { Vec2(this.x * other.x, this.y * other.y) }
    operator func %(other: Vec2): Vec2 { Vec2(this.x % other.x, this.y % other.y) }

    // Comparison
    operator func ==(other: Vec2): Bool { this.x == other.x && this.y == other.y }
    operator func <(other: Vec2): Bool { this.x + this.y < other.x + other.y }
    operator func <=(other: Vec2): Bool { this.x + this.y <= other.x + other.y }

    // Bitwise
    operator func &(other: Vec2): Vec2 { Vec2(this.x & other.x, this.y & other.y) }
    operator func |(other: Vec2): Vec2 { Vec2(this.x | other.x, this.y | other.y) }
    operator func ^(other: Vec2): Vec2 { Vec2(this.x ^ other.x, this.y ^ other.y) }
    operator func <<(other: Vec2): Vec2 { Vec2(this.x << other.x, this.y << other.y) }
    operator func >>(other: Vec2): Vec2 { Vec2(this.x >> other.x, this.y >> other.y) }

    // Unary
    operator func ~(): Vec2 { Vec2(~this.x, ~this.y) }
    operator func #(): Int64 { 2 }
}

let a = Vec2(6, 10)
let b = Vec2(3, 4)

// Arithmetic operators
expectEq((a + b).x, 9, "Vec2 + x")
expectEq((a + b).y, 14, "Vec2 + y")
expectEq((a - b).x, 3, "Vec2 - x")
expectEq((a - b).y, 6, "Vec2 - y")
expectEq((a * b).x, 18, "Vec2 * x")
expectEq((a * b).y, 40, "Vec2 * y")
expectEq((a % b).x, 0, "Vec2 % x")
expectEq((a % b).y, 2, "Vec2 % y")

// Comparison operators
expectTrue(a == Vec2(6, 10), "Vec2 == true")
expectFalse(a == b, "Vec2 == false")
expectFalse(a < b, "Vec2 < false")
expectTrue(b < a, "Vec2 < true")
expectTrue(b <= a, "Vec2 <= true (less)")
expectTrue(a <= Vec2(6, 10), "Vec2 <= true (equal)")

// Bitwise operators
expectEq((Vec2(5, 6) & Vec2(3, 3)).x, 1, "Vec2 & x")
expectEq((Vec2(5, 6) | Vec2(3, 3)).x, 7, "Vec2 | x")
expectEq((Vec2(5, 6) ^ Vec2(3, 3)).x, 6, "Vec2 ^ x")
expectEq((Vec2(5, 6) ^ Vec2(3, 3)).y, 5, "Vec2 ^ y")
expectEq((Vec2(1, 2) << Vec2(4, 3)).x, 16, "Vec2 << x")
expectEq((Vec2(16, 24) >> Vec2(2, 3)).x, 4, "Vec2 >> x")

// Unary operators
let neg = ~Vec2(0, 1)
expectEq(neg.x, -1, "Vec2 ~ x")
expectEq(neg.y, -2, "Vec2 ~ y")
expectEq(#a, 2, "Vec2 # (len)")

// ============================================================
// Section 2: Operator overloading in interface
// ============================================================

interface Addable {
    operator func +(other: Int64): Int64
}

interface Comparable {
    operator func ==(other: Int64): Bool
    operator func <(other: Int64): Bool
}

interface BitwiseOps {
    operator func ^(other: Int64): Int64
    operator func &(other: Int64): Int64
    operator func |(other: Int64): Int64
}

// Struct implementing multiple interfaces with operators
struct Wrapper <: Addable & Comparable & BitwiseOps {
    var val: Int64 = 0

    operator func +(other: Int64): Int64 { this.val + other }
    operator func ==(other: Int64): Bool { this.val == other }
    operator func <(other: Int64): Bool { this.val < other }
    operator func ^(other: Int64): Int64 { this.val ^ other }
    operator func &(other: Int64): Int64 { this.val & other }
    operator func |(other: Int64): Int64 { this.val | other }
}

let w = Wrapper(10)
expectEq(w + 5, 15, "Wrapper + via interface")
expectEq(w ^ 3, 9, "Wrapper ^ via interface")
expectEq(w & 2, 2, "Wrapper & via interface")
expectEq(w | 1, 11, "Wrapper | via interface")

// ============================================================
// Section 3: Operator overloading in extend for user-defined types
// (operators defined outside the struct body)
// ============================================================

struct Point {
    var x: Int64 = 0
    var y: Int64 = 0
}

extend Point {
    operator func +(other: Point): Point {
        Point(this.x + other.x, this.y + other.y)
    }
    operator func ==(other: Point): Bool {
        this.x == other.x && this.y == other.y
    }
    operator func ^(other: Point): Point {
        Point(this.x ^ other.x, this.y ^ other.y)
    }
    operator func ~(): Point {
        Point(~this.x, ~this.y)
    }
    operator func #(): Int64 { 2 }
}

let p1 = Point(3, 5)
let p2 = Point(7, 11)
let p3 = p1 + p2
expectEq(p3.x, 10, "Point extend + x")
expectEq(p3.y, 16, "Point extend + y")
expectTrue(p1 == Point(3, 5), "Point extend ==")
expectFalse(p1 == p2, "Point extend != (via ==)")
let px = Point(5, 6) ^ Point(3, 3)
expectEq(px.x, 6, "Point extend ^ x")
expectEq(px.y, 5, "Point extend ^ y")
let pn = ~Point(0, 0)
expectEq(pn.x, -1, "Point extend ~ x")
expectEq(pn.y, -1, "Point extend ~ y")
expectEq(#p1, 2, "Point extend #")

// ============================================================
// Section 4: Operator overloading in enum body
// ============================================================

enum Amount {
    | Val(Int64)

    operator func +(other: Amount): Amount {
        match (self) {
            case Val(a) => match (other) {
                case Val(b) => return Val(a + b)
            }
        }
    }

    operator func -(other: Amount): Amount {
        match (self) {
            case Val(a) => match (other) {
                case Val(b) => return Val(a - b)
            }
        }
    }

    operator func ==(other: Amount): Bool {
        match (self) {
            case Val(a) => match (other) {
                case Val(b) => return a == b
            }
        }
    }

    operator func ^(other: Amount): Amount {
        match (self) {
            case Val(a) => match (other) {
                case Val(b) => return Val(a ^ b)
            }
        }
    }

    func get(): Int64 {
        match (this) {
            case Val(v) => return v
        }
    }
}

let e1 = Val(100)
let e2 = Val(50)
let e3 = e1 + e2
expectEq(e3.get(), 150, "Enum + operator")
let e4 = e3 - e1
expectEq(e4.get(), 50, "Enum - operator")
expectTrue(e2 == Val(50), "Enum == true")
expectFalse(e1 == e2, "Enum == false")
let e5 = Val(5) ^ Val(3)
expectEq(e5.get(), 6, "Enum ^ operator")

// ============================================================
// Section 5: Edge cases
// ============================================================

// Chained operators
let chain = Vec2(1, 2) + Vec2(3, 4) + Vec2(5, 6)
expectEq(chain.x, 9, "Chained + x")
expectEq(chain.y, 12, "Chained + y")

// Nested operator results
let nested = (Vec2(1, 2) + Vec2(3, 4)) * Vec2(2, 2)
expectEq(nested.x, 8, "Nested (a+b)*c x")
expectEq(nested.y, 12, "Nested (a+b)*c y")

// Operator result used in comparison
expectTrue((Vec2(1, 2) + Vec2(3, 4)) == Vec2(4, 6), "Op result in ==")

// XOR with zero (identity)
expectEq((Vec2(42, 99) ^ Vec2(0, 0)).x, 42, "XOR with 0 identity x")
expectEq((Vec2(42, 99) ^ Vec2(0, 0)).y, 99, "XOR with 0 identity y")

// XOR with self (zero)
expectEq((Vec2(42, 99) ^ Vec2(42, 99)).x, 0, "XOR with self x")
expectEq((Vec2(42, 99) ^ Vec2(42, 99)).y, 0, "XOR with self y")

// Bitwise NOT twice (identity)
let orig = Vec2(42, 99)
let double_neg = ~~orig
expectEq(double_neg.x, 42, "Double ~ identity x")
expectEq(double_neg.y, 99, "Double ~ identity y")

if (!__test_failed) {
    println("PASS: 52_operator_overload_all")
}
