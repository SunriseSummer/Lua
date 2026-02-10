dofile("cangjie-tests/_testing.cj")

// Usage: Error handling patterns — Result enum, chained operations,
// match for success/error, getOrDefault, Option+match for safe code

// --- Section: Define a Result-like enum ---
enum Result {
    | Ok(Int64)
    | Err(String)
}

extend Result {
    func isOk(): Bool {
        return match (this) {
            case Ok(_) => true
            case _ => false
        }
    }
    func isErr(): Bool {
        return !this.isOk()
    }
    func unwrapOr(default: Int64): Int64 {
        return match (this) {
            case Ok(v) => v
            case _ => default
        }
    }
    func map(f: (Int64) -> Int64): Result {
        return match (this) {
            case Ok(v) => Ok(f(v))
            case Err(e) => Err(e)
        }
    }
    func describe(): String {
        return match (this) {
            case Ok(v) => "Ok(${v})"
            case Err(e) => "Err(${e})"
        }
    }
}

// --- Section: Basic Result usage ---
let success = Ok(42)
let failure = Err("not found")

expectTrue(success.isOk(), "Ok isOk")
expectFalse(success.isErr(), "Ok isErr")
expectFalse(failure.isOk(), "Err isOk")
expectTrue(failure.isErr(), "Err isErr")

expectEq(success.unwrapOr(0), 42, "Ok unwrapOr")
expectEq(failure.unwrapOr(-1), -1, "Err unwrapOr")

expectEq(success.describe(), "Ok(42)", "Ok describe")
expectEq(failure.describe(), "Err(not found)", "Err describe")

// --- Section: Chain operations that may fail ---
func parsePositive(n: Int64): Result {
    if (n > 0) {
        return Ok(n)
    }
    return Err("not positive: ${n}")
}

func doubleIfSmall(r: Result): Result {
    return match (r) {
        case Ok(v) => if (v < 100) { Ok(v * 2) } else { Err("too large: ${v}") }
        case Err(e) => Err(e)
    }
}

func addTen(r: Result): Result {
    return match (r) {
        case Ok(v) => Ok(v + 10)
        case Err(e) => Err(e)
    }
}

// Successful chain: 5 -> Ok(5) -> Ok(10) -> Ok(20)
let chain1 = addTen(doubleIfSmall(parsePositive(5)))
expectTrue(chain1.isOk(), "chain1 isOk")
expectEq(chain1.unwrapOr(0), 20, "chain1 value")

// Error at start: -1 -> Err -> Err -> Err
let chain2 = addTen(doubleIfSmall(parsePositive(-1)))
expectTrue(chain2.isErr(), "chain2 isErr")
expectEq(chain2.unwrapOr(-99), -99, "chain2 default")

// Error in middle: 200 -> Ok(200) -> Err("too large") -> Err
let chain3 = addTen(doubleIfSmall(parsePositive(200)))
expectTrue(chain3.isErr(), "chain3 isErr mid-chain")

// --- Section: Match to handle success/error ---
func processResult(r: Result): String {
    return match (r) {
        case Ok(v) => "Success: ${v}"
        case Err(e) => "Error: ${e}"
    }
}

expectEq(processResult(Ok(100)), "Success: 100", "processResult Ok")
expectEq(processResult(Err("timeout")), "Error: timeout", "processResult Err")

// --- Section: Map transforms ---
let mapped = success.map({ v => v * 3 })
expectEq(mapped.unwrapOr(0), 126, "map Ok triple")

let mappedErr = failure.map({ v => v * 3 })
expectTrue(mappedErr.isErr(), "map preserves Err")

// --- Section: getOrDefault pattern ---
func safeDivide(a: Int64, b: Int64): Result {
    if (b == 0) {
        return Err("division by zero")
    }
    return Ok(a / b)
}

expectEq(safeDivide(10, 2).unwrapOr(0), 5, "safeDivide 10/2")
expectEq(safeDivide(10, 0).unwrapOr(-1), -1, "safeDivide 10/0 default")

// --- Section: Option + match for safe code ---
func findUser(id: Int64): ?String {
    if (id == 1) { return Some("Alice") }
    if (id == 2) { return Some("Bob") }
    return None
}

func getUserGreeting(id: Int64): String {
    let user = findUser(id)
    return match (user) {
        case Some(name) => "Hello, ${name}!"
        case None => "User not found"
    }
}

expectEq(getUserGreeting(1), "Hello, Alice!", "greeting user 1")
expectEq(getUserGreeting(2), "Hello, Bob!", "greeting user 2")
expectEq(getUserGreeting(99), "User not found", "greeting unknown")

// Option with if-let for safe field access
func getUserLength(id: Int64): Int64 {
    let user = findUser(id)
    if (let Some(name) <- user) {
        return string.len(name)
    }
    return 0
}

expectEq(getUserLength(1), 5, "Alice length")
expectEq(getUserLength(99), 0, "unknown user length")

// Coalescing for defaults
let name1 = findUser(1) ?? "Anonymous"
let name2 = findUser(99) ?? "Anonymous"
expectEq(name1, "Alice", "coalesce found user")
expectEq(name2, "Anonymous", "coalesce missing user")

// --- Section: Combining Result and Option ---
func lookupAndProcess(id: Int64): Result {
    let user = findUser(id)
    return match (user) {
        case Some(name) => Ok(string.len(name))
        case None => Err("user ${id} not found")
    }
}

let lp1 = lookupAndProcess(1)
expectTrue(lp1.isOk(), "lookupAndProcess 1 isOk")
expectEq(lp1.unwrapOr(0), 5, "lookupAndProcess 1 value")

let lp2 = lookupAndProcess(99)
expectTrue(lp2.isErr(), "lookupAndProcess 99 isErr")
expectEq(lp2.unwrapOr(-1), -1, "lookupAndProcess 99 default")

if (__test_failed) {
    println("FAIL: error_handling_patterns")
} else {
    println("PASS: error_handling_patterns")
}
