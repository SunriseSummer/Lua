dofile("cangjie-tests/_testing.cj")

// Test: Expression statements and field default values

// Field default values
class Config {
    var maxRetries = 3
    var timeout = 30
    var name = "default"
    Config() {}
}

let cfg = Config()
expectEq(cfg.maxRetries, 3, "default maxRetries")
expectEq(cfg.timeout, 30, "default timeout")
expectEq(cfg.name, "default", "default name")

// Override defaults by setting after construction
cfg.maxRetries = 5
expectEq(cfg.maxRetries, 5, "overridden maxRetries")

// Multiple instances share defaults independently
let cfg2 = Config()
expectEq(cfg2.maxRetries, 3, "new instance still has default")

// Field defaults with constructor
class Point {
    var x = 0
    var y = 0
    Point() {}
    Point(newX: Int64, newY: Int64) {
        x = newX
        y = newY
    }
}

let p1 = Point()
expectEq(p1.x, 0, "Point() default x")
expectEq(p1.y, 0, "Point() default y")

let p2 = Point(10, 20)
expectEq(p2.x, 10, "Point(10,20) x")
expectEq(p2.y, 20, "Point(10,20) y")

// Expression statements (non-call expressions used as statements)
class Logger {
    var count = 0
    Logger() {}
    operator func <<(msg: String): Logger {
        count += 1
        this
    }
}

let logger = Logger()
// Expression statement: operator call for side effects
logger << "hello"
logger << "world"
expectEq(logger.count, 2, "logger has 2 entries")

// Float64 built-in methods
extend Float64 {
    func double(): Float64 { return this * 2.0 }
}
let pi = Float64.GetPI()
expectTrue(pi > 3.14, "pi > 3.14")
expectTrue(pi < 3.15, "pi < 3.15")

let converted = Float64(42)
expectEq(converted, 42.0, "Float64(42)")

if (!__test_failed) {
    println("PASS: 35_expr_stmt_field_defaults")
}
