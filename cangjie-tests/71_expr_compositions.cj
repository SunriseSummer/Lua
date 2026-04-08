dofile("cangjie-tests/_testing.cj")

// Test: Expressions used in complex compositions

// -- Section: Block expression as function argument --
func addOne(x) { return x + 1 }
let r1 = addOne({
    let a = 10
    let b = 20
    a + b
})
expectEq(r1, 31, "block expr as func arg")

// -- Section: If expression nested in assignment --
let score = 75
let grade = if (score >= 90) {
    "A"
} else if (score >= 80) {
    "B"
} else if (score >= 70) {
    "C"
} else {
    "D"
}
expectEq(grade, "C", "if-expr grade")

// -- Section: If expression in arithmetic --
let bonus = 10 + if (true) { 5 } else { 0 }
expectEq(bonus, 15, "if expr in arithmetic")

// -- Section: Block expression inside match body --
let val = 2
let r2 = match (val) {
    case 2 =>
        let x = 10
        let y = 20
        x * y
    case _ => 0
}
expectEq(r2, 200, "block in match body")

// -- Section: Nested if expressions --
let a = 5
let b = 10
let r3 = if (a > b) {
    if (a > 20) { "big a" } else { "small a" }
} else {
    if (b > 20) { "big b" } else { "small b" }
}
expectEq(r3, "small b", "nested if-expr")

// -- Section: String interpolation with function calls --
func square(n) { return n * n }
let msg = "sq(4)=${square(4)}, sq(5)=${square(5)}"
expectEq(msg, "sq(4)=16, sq(5)=25", "interpolation with func calls")

// -- Section: String interpolation with expressions --
let arr = [10, 20, 30]
let info = "len=${arr.size}, first=${arr[0]}"
expectEq(info, "len=3, first=10", "interpolation with array ops")

// -- Section: Arithmetic on block expression results --
let r4 = { let x = 7; x * 3 } + { let y = 2; y * 5 }
expectEq(r4, 31, "arithmetic on two blocks")

// -- Section: Block expression with loop --
let r5 = {
    var sum = 0
    for (i in 1..=5) {
        sum = sum + i
    }
    sum
}
expectEq(r5, 15, "block with loop sum 1..=5")

// -- Section: If expression without else returns nil --
let r6 = if (false) { 42 }
expectNil(r6, "if no else is nil")

// -- Section: Chained operations on expression results --
func process(x) { return x * 2 + 1 }
let r7 = process(if (true) { 5 } else { 10 })
expectEq(r7, 11, "func of if-expr")

// -- Section: Block expression with var mutation --
let r8 = {
    var s = ""
    for (i in 0..3) {
        s = s + tostring(i)
    }
    s
}
expectEq(r8, "012", "block with string concat loop")

// -- Section: Nested block expressions --
let r9 = {
    let inner1 = { let _t = 0; 10 + 20 }
    let inner2 = { let _t = 0; 3 * 4 }
    inner1 + inner2
}
expectEq(r9, 42, "nested blocks sum")

if (!__test_failed) {
    println("PASS: 71_expr_compositions")
}
