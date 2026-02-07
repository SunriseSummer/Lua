# MoonCangjie 仓颉奔月计划

本项目在 Lua 运行时上嫁接仓颉编程语言，以实现仓颉（Cangjie）程序的解释执行，将仓颉的现代语言特性与 Lua 的动态运行时能力融合增强。

## 支持的仓颉语言特性

### 变量

- **不可变变量** `let`：`let x: Int64 = 42`
- **可变变量** `var`：`var name: String = "hello"`
- **类型注解**：支持 `Int64`、`Float64`、`String`、`Bool`、`Rune` 等类型标注
- **类型推断**：可省略类型注解，由右值推断类型

### 数据类型

- Int64
- Float64
- Bool
- Rune
- String
- Tuple
- Array
- Range
- Unit
- Option

### 运算符

- **算术运算**：`+`、`-`、`*`、`/`、`%`、`**`（幂运算）
- **比较运算**：`==`、`!=`、`>`、`<`、`>=`、`<=`
- **逻辑运算**：
  - `&&`: 逻辑与
  - `||`: 逻辑或
  - `!`: 逻辑非
- **位运算**：
  - `&`: 按位与
  - `|`: 按位或
  - `^`: 按位异或
  - `!`: 按位求反，也支持 Lua 风格的 `~`
  - `<<`: 循环左移
  - `>>`: 循环右移
- **空值合并**：`??`（Option 类型的默认值运算符）

### 字符串

- **插值字符串**：`"Hello, ${name}!"` 支持在 `${}` 中嵌入任意表达式
- **字符串拼接**：可以使用 `+` 拼接两个字符串，也支持 Lua 风格的 `..`
- **类型转换**：`tostring()`，`tonumber()`

### 控制流

- **条件语句**：`if`、`else if`、`else`，条件需用括号包裹
- **while 循环**：`while (condition) { ... }`
- **for 循环**：
  - 排他范围：`for (i in 1..10) { ... }`
  - 包含范围：`for (i in 1..=10) { ... }`
  - 步长：`for (i in 0..=10:2) { ... }`
- **break 语句**：在循环中提前跳出
- **continue 语句**：跳过当前迭代，继续下一次循环
- **嵌套循环**

### 函数

- **函数定义**：`func add(a: Int64, b: Int64): Int64 { return a + b }`，返回值类型可省略标注
- **一等公民**：函数可以用作参数、返回值、变量赋值
- **函数类型标注**：`func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64)`
- **嵌套函数**与**闭包**：嵌套函数和其捕获的外层变量一起封装为闭包
- **函数重载**：支持同名函数定义不同参数个数的多个版本，运行时按参数个数自动派发
  ```cangjie
  func describe(a: Int64): String { return "one" }
  func describe(a: Int64, b: Int64): String { return "two" }
  describe(1)     // 调用第一个版本
  describe(1, 2)  // 调用第二个版本
  ```
- **Lambda 表达式**：
  - 带参数：`{ x: Int64, y: Int64 => x + y }`
  - 无参数：`{ => println("hello") }`
  - 省略类型标注：`{ x, y => x * y }`
  - 函数体：`{ x => var y = x + 1; return y }`
  - 也支持 Lua 风格的原括号语法：如 `(x, y) => { x + y }`
- **Lambda 作为函数参数**：Lambda 表达式可作为函数类型参数传递
  ```cangjie
  func apply(fn: (Int64, Int64) -> Int64, a: Int64, b: Int64): Int64 { ... }
  apply({ x, y => x + y }, 3, 4)  // 结果为 7
  ```
- **命名参数**：使用 `!` 后缀声明命名参数，可以为命名参数设置默认值
  ```cangjie
  func power(base: Int64, exponent!: Int64 = 2): Int64 { ... }
  power(3, exponent: 2)     // 为命名参数传参，需要写参数名前缀
  power(3)        // 有默认值的命名参数可以省略传参，这时以默认值作为实参
  ```
- **Unit 类型字面量**：`()` 表示空值（映射为 nil）
- **递归**
- **多返回值**

### 自定义类型

#### struct
```cangjie
struct Point {
  var x: Int64
  var y: Int64
  init(x: Int64, y: Int64) {
    this.x = x
    this.y = y
  }
  func toString(): String {
    return "(${x}, ${y})"
  }
}
```

#### class
```cangjie
class Animal {
  var name: String
  init(name: String) {
    this.name = name
  }
  func speak(): String {
    return "${name} says hello!"
  }
}

// 继承使用 <: 语法
class Dog <: Animal {
  var breed: String
  init(name: String, breed: String) {
    this.name = name
    this.breed = breed
  }
  // 方法重写 - 运行时动态派发（多态）
  func speak(): String {
    return "${name} barks!"
  }
}
```

支持的继承特性：
- **单继承**：`class Child <: Parent { ... }`
- **接口实现**：`class Point <: Printable { ... }`
- **多级继承**：`class GuideDog <: Dog`（Dog 已继承 Animal）
- **方法重写**：子类可重写父类方法，运行时动态派发
- **方法继承**：子类自动继承父类未重写的方法
- **多态**：父类引用可调用子类重写的方法

#### 实例化（构造函数调用）
```cangjie
let p = Point(3, 4)  // 调用 init
let dog = Animal("Dog")
```

#### 主构造函数

struct 和 class 支持主构造函数语法，即以类型名作为构造函数名，参数列表中直接定义成员变量，解释器会自动传递实参给对应成员变量进行初始化：

```cangjie
class Wave {
  Wave(let freq: Float64, var phi: Float64) {
    // 其他初始化操作
  }
}

// 等价于：
class Wave {
  let freq: Float64
  var phi: Float64
  init(freq: Float64, phi: Float64) {
    this.freq = freq
    this.phi = phi
    // 其他初始化操作
  }
}

let w = Wave(440.0, 0.5)
println(w.freq)     // 440.0
w.phi = 1.0         // var 字段可修改
```

主构造函数特性：
- 参数前加 `let` 声明为不可变成员变量
- 参数前加 `var` 声明为可变成员变量
- 构造函数体中可以访问参数并执行额外初始化逻辑
- 与 `init` 构造函数互斥，一个类型只能使用其中一种

#### 自动构造函数

当 struct 或 class 的 `var` 字段有默认值但未定义显式 `init` 构造函数时，支持按字段顺序传参构造：

```cangjie
class A {
  var x: Int64 = 0
  var y: Int64 = 1
}
let a = A(2, 4)    // a.x == 2, a.y == 4

struct B {
  var x: Int64 = 0
  var y: String = ""
}
let b = B(1, "hello")  // b.x == 1, b.y == "hello"
```

#### 静态成员函数

静态成员函数属于类型本身，不需要实例即可调用，也没有 `this`/`self` 参数：

```cangjie
struct MathUtils {
  var value: Int64
  init(v: Int64) { this.value = v }

  static func add(a: Int64, b: Int64): Int64 {
    return a + b
  }

  func addToValue(n: Int64): Int64 {
    return add(value, n)  // 成员函数中可直接调用静态函数
  }
}

MathUtils.add(3, 4)  // 通过类型名调用，结果为 7
```

#### 操作符函数重载

在 struct/class/enum 中通过 `operator func` 重载操作符函数。
**可重载操作符**：`+`、`-`、`*`、`/`、`%`、`**`、`==`、`<`、`<=`、`<<`、`>>`、`&`、`|`、`~`、`#`

```cangjie
struct Vector {
  var x: Int64
  var y: Int64
  init(x: Int64, y: Int64) { this.x = x; this.y = y }

  operator func +(other: Vector): Vector {
    return Vector(x + other.x, y + other.y)
  }

  operator func ==(other: Vector): Bool {
    return x == other.x && y == other.y
  }
}

let v = Vector(1, 2) + Vector(3, 4)  // Vector(4, 6)
```

#### this 可省略

在 struct 和 class 的构造函数和实例成员函数中，引用成员变量时可以省略 `this.` 前缀：
```cangjie
struct Counter {
  var count: Int64
  init() {
    count = 0        // 等价于 this.count = 0
  }
  func increment() {
    count = count + 1  // 等价于 this.count = this.count + 1
  }
}
```

### interface（接口）
```cangjie
interface Animal {
  func speak(): String
}

// 自定义类型可实现接口
class Dog <: Animal {
  var name = "Tom"
  // 实现接口中的函数
  func speak(): String {
    return "${name} barks!"
  }
}
```

### extend（扩展）

为已有类型添加成员函数，支持直接扩展和基于接口扩展
```cangjie
// 直接扩展
extend Int64 {
  func describe(): String {
    return "value is ${this}"
  }
}

// 基于接口扩展
interface Printable {
  func toString(): String
}

extend Int64 <: Printable {
  func toString(): String {
    return "value is ${this}"
  }
}
```

在 `interface` 和 `extend` 中也支持 `operator func` 声明或实现。

### 元组类型

```cangjie
// 创建元组（自动0索引）
let t = (1, "hello", true)
println(t[0])  // 1
println(t[1])  // hello
println(t[2])  // true

// 用于函数返回值
func minmax(a: Int64, b: Int64) {
  if (a < b) {
    return (a, b)
  }
  return (b, a)
}

let result = minmax(5, 3)
println(result[0])  // 3
println(result[1])  // 5
```

支持的元组特性：
- **混合类型**：元组元素可以是不同类型
- **0 索引访问**：`t[0]`、`t[1]` 等
- **嵌套元组**：元组元素可以是其他元组
- **函数返回值**：可用元组包装多个返回值
- **元组模式匹配**：`case (x, y) => ...`

### 枚举类型

```cangjie
// 基本枚举
enum Direction {
  | North
  | South
  | East
  | West
}

// 带参数的枚举构造器
enum Color {
  | Red
  | Green
  | Blue(Int64)
  | RGB(Int64, Int64, Int64)

  // 枚举成员函数
  func describe(): String {
    match (this) {
      case Red =>
        return "Red"
      case Blue(v) =>
        return "Blue(${v})"
      case _ =>
        return "Other"
    }
  }
}

// 泛型枚举
enum Option<T> {
  | Some(T)
  | None

  func isPresent(): Bool {
    match (this) {
      case Some(v) =>
        return true
      case None =>
        return false
    }
  }
}

// 递归枚举（如表达式树）
enum Expr {
  | Num(Int64)
  | Add(Expr, Expr)
  | Sub(Expr, Expr)
}

// 枚举操作符重载
enum Money {
  | Yuan(Int64)

  operator func +(other: Money): Money {
    match (self) {
      case Yuan(a) => match (other) {
        case Yuan(b) => return Yuan(a + b)
      }
    }
  }
}

let total = Yuan(100) + Yuan(200)  // Yuan(300)
```

支持的枚举特性：
- **无参构造器**：`| Red` - 创建单例值
- **带参构造器**：`| Blue(Int64)` - 创建工厂函数
- **多参数构造器**：`| RGB(Int64, Int64, Int64)`
- **递归枚举**：构造器参数可引用枚举自身类型（如 `Node(Int64, Tree, Tree)`）
- **行内构造器**：支持 `Empty | Leaf(Int64) | Node(Int64, Tree, Tree)` 行内语法（首个构造器无需 `|` 前缀）
- **泛型枚举**：`enum Option<T> { | Some(T) | None }`
- **成员函数**：枚举类型内可定义 `func`，通过 `this` 引用当前枚举实例
- **操作符重载**：在枚举中支持 `operator func` 重载运算符（`+`、`-`、`*`、`==` 等），使枚举实例支持算术和比较操作
- **直接访问**：无命名冲突时可直接使用枚举项名字 `Red`，也可使用限定名 `Color.Red`

### 泛型

- **泛型函数**：`func identity<T>(x: T): T { return x }`
- **泛型 struct**：`struct Box<T> { var value: T; ... }`
- **多类型参数**：`struct Pair<T, U> { ... }`
- **泛型方法**
- **类型参数推断**

### Option 类型

内建支持 `Option<T>` 类型，提供 `?Type` 语法糖：

```cangjie
// ?Int64 等价于 Option<Int64>
let a: ?Int64 = Some(42)
let b: ?Int64 = None

// 方法
a.isSome()          // true
a.isNone()          // false
a.getOrThrow()      // 42（None 时抛错）
b.getOrDefault({ => 0 })   // 0（参数为 () -> T 类型函数）

// 模式匹配
match (a) {
  case Some(v) => println(v)
  case None => println("none")
}

// 空值合并运算符 ??
let x = a ?? 0      // 42（从 Some 中取值）
let y = b ?? 99     // 99（None 使用默认值）
```

### 模式匹配

```cangjie
// 枚举模式匹配（=> 后无需大括号）
match (color) {
  case Red =>
    println("red")
  case Blue(val) =>
    println("blue: ${val}")
  case _ =>
    println("other")
}

// 常量模式匹配
match (x) {
  case 0 =>
    println("zero")
  case 1 =>
    println("one")
  case _ =>
    println("other")
}

// 类型模式匹配
match (animal) {
  case d: Dog =>
    println(d.bark())
  case c: Cat =>
    println("${c.name} meows!")
  case _ =>
    println("unknown")
}

// 元组模式匹配
match (pair) {
  case (x, y) =>
    println("pair: ${x}, ${y}")
}

// 递归枚举求值
func eval(e) {
  match (e) {
    case Num(n) =>
      return n
    case Add(a, b) =>
      return eval(a) + eval(b)
    case Sub(a, b) =>
      return eval(a) - eval(b)
  }
}
```

支持的模式匹配特性：
- **枚举构造器模式**：匹配枚举变体并解构参数
- **常量模式**：匹配整数、浮点数、字符串字面量
- **通配符模式**：`_` 匹配任意值
- **类型模式**：`case x: Type =>` 按类型匹配并绑定变量
- **元组模式**：`case (a, b) =>` 解构元组元素
- **参数绑定**：在枚举/元组模式中绑定解构值到局部变量
- **多分支**：按顺序匹配，命中第一个匹配的分支
- **无大括号语法**：`=>` 后直接写多行语句，由下一个 `case` 或 `}` 分隔
- **if-let 模式匹配**：`if (let Pattern <- expr) { ... }` 解构并判断
- **while-let 模式匹配**：`while (let Pattern <- expr) { ... }` 循环解构
- **与逻辑表达式混合**：`if (let Some(v) <- expr && v > 0)` 或 `if (let Some(v) <- expr || fallback)`

#### if-let 和 while-let

```cangjie
// if-let：解构 Option 值
let opt = Some(42)
if (let Some(v) <- opt) {
  println("got: ${v}")    // got: 42
}

// 与 && 混合：模式匹配成功且额外条件满足
if (let Some(v) <- opt && v > 10) {
  println("v is ${v}, greater than 10")
}

// 与 || 混合：模式匹配成功或备选条件为真
if (let Some(v) <- opt || fallbackCondition) {
  println("entered")
}

// while-let：循环解构
while (let Some(v) <- getNext()) {
  println(v)
}
```

### 表达式求值

#### if 表达式

if 语句可以用作表达式，其值为所执行分支最后一个表达式的值。如果没有分支被执行，值为 nil：

```cangjie
let x = if (score >= 90) { "A" } else if (score >= 80) { "B" } else { "C" }

// 没有 else 分支时，未匹配的 if 表达式值为 nil
let y = if (false) { 42 }  // y == nil
```

#### match 表达式

match 语句可以用作表达式，其值为所匹配分支最后一个表达式的值。如果没有分支被匹配，值为 nil：

```cangjie
let name = match (day) {
  case 1 => "Monday"
  case 2 => "Tuesday"
  case _ => "Other"
}
```

#### 代码块表达式

代码块 `{ ... }` 可以用作表达式，值为其中最后一个表达式的值。空代码块的值为 nil：

```cangjie
let sum = {
  var s = 0
  for (i in 0..100) {
    s = s + i
  }
  s
}
```

#### 函数隐式返回

函数体中如果最后一个语句是表达式（不是 return），则该表达式的值作为函数的返回值：

```cangjie
func add(a: Int64, b: Int64): Int64 {
  a + b
}

func greet(name: String): String {
  "Hello, " + name + "!"
}
```

#### 未确定求值规则的表达式

对于 while、for 等尚未确定求值规则的表达式，其值始终为 nil：

```cangjie
let r = while (false) { println("unreachable") }  // r == nil
let f = for (i in 0..0) { println(i) }             // f == nil
```

### 多维数组与 Array 初始化

```cangjie
// 多维数组
let matrix = [[1, 2, 3], [4, 5, 6]]
println(matrix[0][1])    // 2

// Array 初始化（指定大小和初始值）
let zeros = Array<Int64>(5, 0)           // [0, 0, 0, 0, 0]
let squares = Array<Int64>(4, { i: Int64 => i * i })  // [0, 1, 4, 9]

// 多维 Array 初始化
let grid = Array<Array<Int64>>(3, { i: Int64 =>
  Array<Int64>(3, { j: Int64 => i * 3 + j })
})
```

### 数组切片，区间索引

支持使用区间表达式对数组进行切片取值和赋值：

```cangjie
let arr = [10, 20, 30, 40, 50, 60]

// 左闭右开区间取值：arr[start..end] 取 [start, end) 范围
let r1 = arr[0..3]      // [10, 20, 30]

// 闭区间取值：arr[start..=end] 取 [start, end] 范围
let r2 = arr[2..=4]      // [30, 40, 50]

// 区间赋值：将值数组写入指定范围
var arr2 = [0, 0, 0, 0, 0, 0]
arr2[1..=3] = [100, 200, 300]  // arr2 变为 [0, 100, 200, 300, 0, 0]
```

### 集合类型

- **ArrayList**：基于泛型实现的动态数组
  - 方法：`add()`、`get()`、`set()`、`removeAt()`、`indexOf()`、`contains()`、`clear()`、`forEach()`、`map()`、`filter()`
  - 属性：`size`、`isEmpty()`

- **HashMap**：基于泛型实现的哈希表
  - 方法：`put()`、`get()`、`containsKey()`、`remove()`、`forEach()`

## 融合 Lua 的扩展能力（动态特性）

本项目的独特之处在于将仓颉的静态类型语法与 Lua 的动态运行时无缝融合，提供以下扩展能力：

### 动态类型

- **nil 值**：支持 Lua 的 nil 空值
- **多重赋值**：`let a, b = 100, 200`
- **多返回值**：函数可返回多个值
- **动态类型变量**：变量可在运行时持有任意类型值
- **鸭子类型**：方法调用基于运行时对象实际拥有的方法，无需静态类型声明

### 动态多态与派发

- **运行时方法解析**：方法调用在运行时沿继承链查找，支持动态派发
- **动态方法绑定**：方法访问自动绑定 self 参数
- **动态枚举操作**：枚举值可通过通用函数（如 map、filter）进行操作，也可直接通过索引 `[1]`、`[2]` 访问构造器参数（仓颉语法超集扩展）
- **类型灵活的模式匹配**：match 表达式基于运行时 tag/类型匹配，无需编译期类型检查

### 函数式编程

- **Lambda 表达式**：花括号语法 `{ x, y => x + y }` 和圆括号语法 `() => expr` 均支持
- **高阶函数**：函数可作为参数传递、作为返回值返回
- **函数类型标注**：参数可标注函数类型 `fn: (Int64, Int64) -> Int64`
- **柯里化**：通过嵌套 Lambda 实现：`let multiply = { a => { b => a * b } }`
- **函数组合**：`compose(f, g)` 和管道操作 `pipe(value, fns)`
- **立即调用**：`({ x, y => x + y })(3, 4)` 直接调用匿名 Lambda

### Table（表）

- **关联数组**：`let dict = {}; dict["key"] = "value"`
- **长度运算符**：`#table` 获取序列长度
- **迭代器**：
  - `ipairs()` - 有序数字索引迭代
  - `pairs()` - 遍历所有键值对

### 元编程

- **元表（Metatable）**：通过 `setmetatable()` 设置
- **元方法**：`__index`（索引查找）、`__add`（加法重载）、`__tostring`（字符串表示）
- **方法调用链**：支持 `:` 语法自动传递 self
- **运算符重载**

### 错误处理

- **安全调用**：`pcall(func() { ... })` 捕获运行时错误
- **抛出错误**：`error("message")`

### 协程

- **创建协程**：`coroutine.create(func() { ... })`
- **挂起/恢复**：`coroutine.yield(value)` / `coroutine.resume(co)`
- **值传递**：协程间可传递返回值
- **生产者-消费者模式**

## 错误检查与诊断

本解释器实现了多层次的错误检查和友好的诊断信息：

### 词法错误
- **未结束的字符串**：检测缺少闭合引号的字符串字面量
- **无效转义序列**：检测 `\q` 等非法转义字符
- **格式错误的数字**：检测 `0xGG` 等无效数字字面量
- **未结束的块注释**：检测缺少 `*/` 闭合的注释

### 语法错误
- **缺失括号**：`if`、`while`、`for`、`match` 条件必须用 `()` 包裹
- **缺失花括号**：检测未闭合的 `struct`/`class`/`enum`/`match` 体
- **缺失箭头**：`match` 的 `case` 分支必须使用 `=>`
- **缺失名称**：`struct`/`class`/`func` 后必须有名称
- **空类型注解**：`let x: = 10` 等冒号后缺少类型名的情况
- **非法成员**：`struct`/`class` 体内允许 `func`、`init`、`let`、`var`、`static func`、`operator func`
- **非法枚举内容**：`enum` 体内只允许 `|`、构造器名、`func` 或 `operator func`
- **非法接口内容**：`interface` 体内只允许 `func` 声明

### 语义错误
- **不可变变量赋值**：`let` 声明的变量不可重新赋值
- **let 缺少初始化**：`let` 声明必须提供初始值
- **循环外 break**：`break` 只能在循环体内使用
- **循环外 continue**：`continue` 只能在循环体内使用
- **同名变量重定义**：同一作用域内重复定义同名变量（不同作用域允许遮蔽）
- **同名类型重定义**：同一作用域内重复定义同名 struct/class/enum/interface
- **运行时类型错误**：通过 Lua VM 检测算术、比较等操作的类型不匹配

## 使用限制

1. **类型注解为编译期提示**：类型注解在解析阶段被读取后跳过，不进行静态类型检查，所有类型检查在运行时由 Lua VM 完成
2. **继承**：支持 `class B <: A` 单继承语法，子类继承父类方法并可重写，运行时动态派发；不支持 `open`/`override` 修饰符（所有方法默认可重写）
3. **接口**：`interface` 声明创建标记表，方法签名被解析但不做编译期接口一致性检查；class 可使用 `<:` 声明实现接口
4. **泛型**：泛型类型参数在解析阶段被跳过，依赖 Lua 的动态类型在运行时实现多态
5. **内置类型扩展**：扩展方法通过元表 `__index` 实现，对同一类型的多次扩展会叠加方法（后续扩展的方法会优先被查找）
6. **隐式 this**：仅在 `struct/class` 体内声明的 `var/let` 字段名可被隐式解析为 `self.field`，局部变量同名时局部变量优先
7. **访问控制**：不支持 `public`/`private`/`protected` 访问修饰符
8. **元组嵌套字面量**：不支持直接嵌套元组字面量 `((1,2), (3,4))`，需通过变量间接嵌套
9. **枚举类型**：支持带参数的枚举构造器、递归枚举、泛型枚举、成员函数和操作符重载
10. **模式匹配**：支持枚举模式、常量模式、通配符模式、类型模式和元组模式，但不支持守卫条件（where）
11. **异常处理**：不支持 `try/catch/finally`，使用 Lua 的 `pcall` 替代
12. **文件模块**：不支持仓颉的 `package`/`import` 模块系统，使用 Lua 的 `require` 替代
13. **命名参数**：支持 `param!: Type = default` 声明形式，未传参时自动使用默认值；支持 `name: value` 命名调用语法
14. **Lambda 表达式**：花括号 Lambda `{ x => expr }` 中，如果 body 包含赋值语句则使用 `statlist` 解析（需显式 `return`），否则自动返回表达式值
15. **幂运算**：`**` 运算结果为浮点数（遵循 Lua 底层实现），如 `2 ** 10` 返回 `1024.0`
16. **默认值检测**：默认值检测基于 nil 判断（仅当参数为 nil 时使用默认值），传递 `false` 不会被错误地替换为默认值
17. **Unit 类型**：`()` 映射为 nil，可用作表达式或空操作语句
18. **表达式求值**：if、match、代码块可用作表达式，其值为所执行分支（或代码块）最后一个表达式的值；函数体支持隐式返回最后一个表达式的值；while/for 等未确定求值规则的表达式其值为 nil
19. **数组区间索引**：支持 `arr[start..end]`（左闭右开区间）和 `arr[start..=end]`（闭区间）取值，以及 `arr[start..end] = values` 区间赋值
20. **主构造函数**：struct/class 支持以类型名命名的主构造函数，参数前加 `let`/`var` 自动声明为成员变量

## 构建与测试

### 构建

项目使用 GNU Make 构建系统，编译产物输出到 `build/` 目录。

```bash
# 标准构建（生成 lua 可执行文件）
make

# 带内部测试支持的构建（启用断言和调试信息）
make TESTS='-DLUA_USER_H="ltests.h" -Og -g'

# 清理构建产物
make clean
```

构建成功后，`lua` 可执行文件生成在项目根目录下。

### 运行

```bash
# 运行仓颉源文件
./lua example.cj

# 交互式模式（let/var 声明在行间保持有效）
./lua
```

### 测试

```bash
# 运行所有仓颉测试用例（包括基础测试、扩展特性、用法示例和诊断测试）
bash run_tests.sh
```

测试脚本会自动发现并执行 `cangjie-tests/` 下所有子目录中的 `.cj` 测试文件，并汇总结果。

## 项目结构

```
.
├── makefile                      # 构建脚本
├── run_tests.sh                  # 测试运行脚本
├── readme.md                     # 项目文档
├── src/                          # 源代码目录
│   ├── core/                     # Lua 核心引擎
│   │   ├── runtime/              # 运行时执行引擎
│   │   │   ├── lapi.c            #   C API 接口
│   │   │   ├── ldebug.c          #   调试接口与钩子
│   │   │   ├── ldo.c             #   函数调用与栈管理
│   │   │   ├── lfunc.c           #   函数原型与闭包
│   │   │   ├── lopcodes.c        #   操作码定义
│   │   │   ├── lstate.c          #   全局状态与线程状态
│   │   │   ├── lvm.c             #   虚拟机执行引擎
│   │   │   └── lzio.c            #   缓冲流 I/O
│   │   ├── memory/               # 内存管理
│   │   │   ├── lgc.c             #   垃圾收集器
│   │   │   └── lmem.c            #   内存分配器
│   │   └── object/               # 对象与类型系统
│   │       ├── lctype.c          #   字符类型工具
│   │       ├── lobject.c         #   对象/值操作
│   │       ├── lstring.c         #   字符串驻留
│   │       ├── ltable.c          #   表（哈希表）实现
│   │       └── ltm.c             #   元方法（标签方法）
│   ├── compiler/                 # 编译器
│   │   ├── lcode.c               #   代码生成器
│   │   ├── ldump.c               #   字节码序列化
│   │   ├── llex.c                #   词法分析器（支持仓颉关键字、运算符、字符串插值）
│   │   ├── lparser.c             #   语法分析器（支持仓颉语法：struct/class/enum/match/lambda 等）
│   │   └── lundump.c             #   字节码反序列化
│   ├── libs/                     # 标准库与运行时库
│   │   ├── lauxlib.c             #   辅助库
│   │   ├── lbaselib.c            #   基础库（Lua 标准函数）
│   │   ├── lbaselib_cj.c         #   仓颉运行时支持（类/结构体/枚举/元组/继承/模式匹配）
│   │   ├── lcorolib.c            #   协程库
│   │   ├── ldblib.c              #   调试库
│   │   ├── linit.c               #   库初始化
│   │   ├── liolib.c              #   I/O 库
│   │   ├── lmathlib.c            #   数学库
│   │   ├── loadlib.c             #   动态加载库
│   │   ├── loslib.c              #   操作系统库
│   │   ├── lstrlib.c             #   字符串库
│   │   ├── ltablib.c             #   表操作库
│   │   └── lutf8lib.c            #   UTF-8 库
│   ├── include/                  # 头文件
│   │   ├── lua.h                 #   Lua 公共 API
│   │   ├── luaconf.h             #   编译配置
│   │   ├── lualib.h              #   标准库接口
│   │   ├── lauxlib.h             #   辅助库接口
│   │   ├── lbaselib_cj.h         #   仓颉运行时接口
│   │   └── ...                   #   其他内部头文件
│   ├── app/                      # 应用程序
│   │   ├── lua.c                 #   Lua/仓颉解释器入口
│   │   └── onelua.c              #   单文件编译版本
│   └── tests/                    # 内部测试支持
│       ├── ltests.c              #   内部测试框架
│       └── ltests.h              #   测试头文件
├── cangjie-tests/                # 仓颉语言测试用例
│   ├── *.cj                      #   基础语言特性测试（32 个）
│   ├── ext-features/             #   融合 Lua 动态特性的扩展测试（5 个）
│   ├── usages/                   #   综合应用案例（6 个）
│   └── diagnosis/                #   错误检测和诊断测试（4 个）
├── testes/                       # Lua 原生测试套件
└── manual/                       # Lua 参考手册
```

## 参考

- [仓颉语言文档](https://cangjie-lang.cn/docs)
- [Lua 官方网站](https://www.lua.org/)
