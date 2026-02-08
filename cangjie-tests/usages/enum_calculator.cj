dofile("cangjie-tests/_testing.cj")

// Usage: Simple calculator with enum expression tree

enum CalcExpr {
    | Num(Float64)
    | Add(CalcExpr, CalcExpr)
    | Sub(CalcExpr, CalcExpr)
    | Mul(CalcExpr, CalcExpr)
    | Div(CalcExpr, CalcExpr)
}

func evaluate(e: CalcExpr): Float64 {
    match (e) {
        case Num(n) => return n
        case Add(a, b) => return evaluate(a) + evaluate(b)
        case Sub(a, b) => return evaluate(a) - evaluate(b)
        case Mul(a, b) => return evaluate(a) * evaluate(b)
        case Div(a, b) => return evaluate(a) / evaluate(b)
    }
}

func exprToString(e: CalcExpr): String {
    match (e) {
        case Num(n) => return tostring(n)
        case Add(a, b) => return "(${exprToString(a)} + ${exprToString(b)})"
        case Sub(a, b) => return "(${exprToString(a)} - ${exprToString(b)})"
        case Mul(a, b) => return "(${exprToString(a)} * ${exprToString(b)})"
        case Div(a, b) => return "(${exprToString(a)} / ${exprToString(b)})"
    }
}

// (3 + 4) * 2 = 14
let expr1 = Mul(Add(Num(3.0), Num(4.0)), Num(2.0))
expectEq(evaluate(expr1), 14.0, "calc (3+4)*2")
expectEq(exprToString(expr1), "((3.0 + 4.0) * 2.0)", "expr string (3+4)*2")

// 10 / (5 - 3) = 5
let expr2 = Div(Num(10.0), Sub(Num(5.0), Num(3.0)))
expectEq(evaluate(expr2), 5.0, "calc 10/(5-3)")

// ((1 + 2) * (3 + 4)) - 5 = 16
let expr3 = Sub(
    Mul(
        Add(Num(1.0), Num(2.0)),
        Add(Num(3.0), Num(4.0))
    ),
    Num(5.0)
)
expectEq(evaluate(expr3), 16.0, "calc ((1+2)*(3+4))-5")

// Deeply nested: ((2*3) + (4*5)) / (6-1) = (6+20)/5 = 5.2
let expr4 = Div(
    Add(
        Mul(Num(2.0), Num(3.0)),
        Mul(Num(4.0), Num(5.0))
    ),
    Sub(Num(6.0), Num(1.0))
)
expectEq(evaluate(expr4), 5.2, "calc complex nested")

if (!__test_failed) {
    println("PASS: enum_calculator")
}
