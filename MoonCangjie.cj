/*
 * MoonCangjie 仓颉奔月计划 🌕
 * https://github.com/SunriseSummer/Lua/tree/cangjie-inside-claude-opus4.6
 * 本项目在 Lua 运行时上嫁接仓颉编程语言，以实现仓颉程序的解释执行
 * 将仓颉的现代语言特性与 Lua 的动态运行时能力融合增强
 */ 

// 变量与基础数据类型
let int: Int64 = 2026
var float: Float64 = 3.14
let char: Rune = '🌏'
let string: String = "Cangjie"
let tuple: (Int64, String) = (2026, "Cangjie")
let array = Array<Int64>(5, { i: Int64 => i * i + 1 })
println(tuple[1])
println("${char} -> ${ 2025 + 1 }")

// for 循环与区间表达式
array[3..5] = [2, 1] // 区间索引
for (i in 0..array.size) {
    print("${array[i]} ")
}
println()

// 函数用作参数/返回值/变量赋值，嵌套函数，闭包，命名参数，默认值
func node(value: String,
    left!: () -> Unit = {=>}, right!: () -> Unit = {=>}) {
    return { =>
        left()
        print(value)
        right()
    }
}
let closure = node("A",
    left: node("B", left: node("C", right: node("D"))),
    right: node("E", left: node("F"), right: node("G")))
closure() // 输出 CDBAFEG
println()

// 结构体与类，自动构造函数，主构造函数，操作符重载
struct Point {
    var x: Float64 = 0.0
    var y: Float64 = 0.0
    operator func +(that: Point): Point {
        Point(this.x + that.x, this.y + that.y)
    }
}
class Circle {
    Circle(var center: Point, var radius: Float64) {
        if (radius < 1.0) {
            this.radius = 1.0
        }
    }
    func info(): String {
        "${center.x}, ${center.y}, ${radius}"
    }
}
let p = Point(1.0, 1.5) + Point(2.0, 1.0)
let c = Circle(p, 3.14)
println(c.info())

// 枚举，代数特性，模式匹配
enum Tree {
    Empty | Leaf(Int64) | Node(Int64, Tree, Tree)

    func traverse(): Unit {
        match (this) {
            case Empty => ()
            case Leaf(value) => print(value)
            case Node(value, left, right) =>
                left.traverse()
                print(value)
                right.traverse()
        }
    }
}
let tree = Node(1,
    Node(2, Node(3, Empty, Leaf(4)), Empty),
    Node(5, Leaf(6), Leaf(7)))
tree.traverse()
println()

// 接口与扩展
interface Moveable {
    func move(dx: Float64, dy: Float64): Float64
}
extend Point <: Moveable {
    func move(dx: Float64, dy: Float64): Float64 {
        this.x = this.x + dx
        this.y = this.y + dy
        return (dx ** 2 + dy ** 2) ** 0.5
    }
}
let pt = Point(1.0, 1.0)
let distance = p.move(3.0, 4.0)
println(distance)

extend Int64 {
    func isEven(): Bool {
        this % 2 == 0
    }
}
let num: Int64 = 2026
println(num.isEven())

// Option
let empty: ?Int64 = None
println(empty.getOrDefault({=> 0}))
let valid: ?Int64 = Some(2026)
println(valid.getOrDefault({=> 0}))

// 模式匹配
let types = match (pt) {
  case c: Circle => "Circle"
  case p: Point => "Point"
  case _ => "Unknown"
}
println(types)

// if-let，while-let，模式匹配混合逻辑运算
if (let Some(value) <- valid) {
    println(value)
}
var count: Int64 = 3
while (let Some(value) <- valid && count > 0) {
    println(count)
    count = count - 1
}

//======== 融合 Lua 引擎的动态特性 ========//
// dynamic table
let dict = {}
dict["name"] = "Cangjie"
dict["version"] = 1
dict[42] = "answer"
for (k, v in pairs(dict)) {
    println("${k} -> ${v}")
}

// multiple return and multiple assignment
func divmod(a: Int64, b: Int64) {
  return a / b, a % b
}
let q, r = divmod(17, 5)
println("${q}, ${r}")

// 动态解释执行
let code = "let f = { x, y => x ** y }; println(f(2, 3))"
let chunk, err = load(code)
let ok, er = pcall(chunk) // print 8.0
println(ok)

