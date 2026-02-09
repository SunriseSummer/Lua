dofile("cangjie-tests/_testing.cj")

// Comprehensive usage: Expression evaluator with variables and error handling

// --- Expression tree with Option results ---
enum CalcExpr {
    | Lit(Float64)
    | Add(CalcExpr, CalcExpr)
    | Sub(CalcExpr, CalcExpr)
    | Mul(CalcExpr, CalcExpr)
    | Div(CalcExpr, CalcExpr)
}

extend CalcExpr {
    func eval(): ?Float64 {
        return match(this) {
            case Lit(v) => Some(v)
            case Add(a, b) => {
                let va = a.eval()
                let vb = b.eval()
                if (va.isNone() || vb.isNone()) {
                    None
                } else {
                    Some(va.getOrDefault(0.0) + vb.getOrDefault(0.0))
                }
            }
            case Sub(a, b) => {
                let va = a.eval()
                let vb = b.eval()
                if (va.isNone() || vb.isNone()) {
                    None
                } else {
                    Some(va.getOrDefault(0.0) - vb.getOrDefault(0.0))
                }
            }
            case Mul(a, b) => {
                let va = a.eval()
                let vb = b.eval()
                if (va.isNone() || vb.isNone()) {
                    None
                } else {
                    Some(va.getOrDefault(0.0) * vb.getOrDefault(0.0))
                }
            }
            case Div(a, b) => {
                let va = a.eval()
                let vb = b.eval()
                if (va.isNone() || vb.isNone()) {
                    None
                } else {
                    let divisor = vb.getOrDefault(0.0)
                    if (divisor == 0.0) {
                        None
                    } else {
                        Some(va.getOrDefault(0.0) / divisor)
                    }
                }
            }
        }
    }
}

// Simple literal
let e1 = Lit(42.0)
expectEq(e1.eval().getOrDefault(0.0), 42.0, "literal eval")

// Addition
let e2 = Add(Lit(3.0), Lit(4.0))
expectEq(e2.eval().getOrDefault(0.0), 7.0, "add eval")

// Complex expression: (2 + 3) * (10 - 4)
let e3 = Mul(Add(Lit(2.0), Lit(3.0)), Sub(Lit(10.0), Lit(4.0)))
expectEq(e3.eval().getOrDefault(0.0), 30.0, "complex expr eval")

// Division by zero returns None
let e4 = Div(Lit(10.0), Lit(0.0))
expectTrue(e4.eval().isNone(), "div by zero is None")

// Division by zero with null coalescing
let safeResult = e4.eval() ?? -1.0
expectEq(safeResult, -1.0, "div by zero with ?? gives -1")

// Nested: 100 / (5 * 2)
let e5 = Div(Lit(100.0), Mul(Lit(5.0), Lit(2.0)))
expectEq(e5.eval().getOrDefault(0.0), 10.0, "nested div eval")

// --- Section: Using closures for expression builders ---
let makeAdd = { a: Float64, b: Float64 => Add(Lit(a), Lit(b)) }
let makeMul = { a: Float64, b: Float64 => Mul(Lit(a), Lit(b)) }

let builtExpr = makeAdd(10.0, 20.0)
expectEq(builtExpr.eval().getOrDefault(0.0), 30.0, "builder add")

let builtExpr2 = makeMul(6.0, 7.0)
expectEq(builtExpr2.eval().getOrDefault(0.0), 42.0, "builder mul")

if (!__test_failed) {
    println("PASS: calc_expr_evaluator")
}
