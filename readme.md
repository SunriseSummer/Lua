# Lua-Cangjie 解释器

本项目基于 Lua 解释器改造，使其支持解析和执行仓颉（Cangjie）编程语言语法。将仓颉的静态类型化面向对象特性与 Lua 的动态运行时能力融合，形成一种独特的混合语言实现。

## 支持的仓颉语言特性

### 变量与类型

- **不可变变量** `let`：`let x: Int64 = 42`
- **可变变量** `var`：`var name: String = "hello"`
- **类型注解**：支持 `Int64`、`Float64`、`String`、`Bool`、`Rune` 类型标注
- **类型推断**：可省略类型注解，由右值推断类型
- **数组类型**：支持 0 索引数组及 `.size` 属性

### 控制流

- **条件语句**：`if`、`else if`、`else`，条件需用括号包裹
- **while 循环**：`while (condition) { ... }`
- **for 循环**：
  - 排他范围：`for (i in 1..10) { ... }`
  - 包含范围：`for (i in 1..=10) { ... }`
  - 步长：`for (i in 0..=10:2) { ... }`
- **break 语句**：在循环中提前跳出
- **嵌套循环**

### 运算符

- **算术运算**：`+`、`-`、`*`、`/`、`%`、`^`（幂运算）
- **比较运算**：`==`、`!=`、`>`、`<`、`>=`、`<=`
- **逻辑运算**：`and`、`or`、`not`（`!`）
- **字符串连接**：`..`
- **位运算**：`<<`、`>>`、`~`

### 字符串

- **字符串插值**：`"Hello, ${name}!"` 支持在 `${}` 中嵌入任意表达式
- **多重插值**：单个字符串中可使用多个 `${}`
- **类型转换**：`tostring()`、`tonumber()`

### 函数

- **函数定义**：`func add(a: Int64, b: Int64): Int64 { return a + b }`
- **返回类型注解**（可选）
- **一等公民**：函数可赋值给变量、作为参数传递
- **高阶函数**：支持函数作为参数和返回值
- **嵌套函数**与**闭包**：捕获外部变量
- **Lambda 表达式**：`let square = (x) => x * x` 或 `() => 42`
- **递归**
- **多返回值**

### 面向对象

#### struct（值类型）
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

#### class（引用类型）与继承
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

#### interface（接口）
```cangjie
interface Printable {
  func toString(): String
}
```

#### extend（扩展）

为已有类型添加方法，支持接口实现声明：
```cangjie
// 扩展用户定义类型
extend Point <: Printable {
  func describe(): String {
    return "Point at (${this.x}, ${this.y})"
  }
}

// 扩展内置基础类型
extend Int64 <: Printable {
  func double(): Int64 {
    return this * 2
  }
}
```

支持扩展的内置类型：`Int64`、`Float64`、`String`、`Bool`

#### 隐式 this

在 struct 和 class 的构造函数和成员函数中，引用成员变量时可以省略 `this.` 前缀：
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

隐式 `this` 和显式 `this.` 可混合使用。

#### 构造函数调用
```cangjie
let p = Point(3, 4)     // 自动调用 init
let dog = Animal("Dog")
```

### 泛型

- **泛型函数**：`func identity<T>(x: T): T { return x }`
- **泛型 struct**：`struct Box<T> { var value: T; ... }`
- **多类型参数**：`struct Pair<T, U> { ... }`
- **泛型方法**
- **类型参数推断**

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
        return "Blue(" .. tostring(v) .. ")"
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
```

支持的枚举特性：
- **无参构造器**：`| Red` - 创建单例值
- **带参构造器**：`| Blue(Int64)` - 创建工厂函数
- **多参数构造器**：`| RGB(Int64, Int64, Int64)`
- **递归枚举**：构造器参数可引用枚举自身类型
- **泛型枚举**：`enum Option<T> { | Some(T) | None }`
- **成员函数**：枚举类型内可定义 `func`，通过 `this` 引用当前枚举实例
- **直接访问**：`Color.Red` 或省略前缀 `Red`

### 模式匹配

```cangjie
// 枚举模式匹配（=> 后无需大括号）
match (color) {
  case Red =>
    println("red")
  case Blue(val) =>
    println("blue: " .. tostring(val))
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
    println(c.name .. " meows!")
  case _ =>
    println("unknown")
}

// 元组模式匹配
match (pair) {
  case (x, y) =>
    println("pair: " .. tostring(x) .. ", " .. tostring(y))
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

## 使用限制

1. **类型注解为编译期提示**：类型注解在解析阶段被读取后跳过，不进行静态类型检查，所有类型检查在运行时由 Lua VM 完成
2. **继承**：支持 `class B <: A` 单继承语法，子类继承父类方法并可重写，运行时动态派发；不支持 `open`/`override` 修饰符（所有方法默认可重写）
3. **接口**：`interface` 声明创建标记表，方法签名被解析但不做编译期接口一致性检查；class 可使用 `<:` 声明实现接口
4. **泛型**：泛型类型参数在解析阶段被跳过，依赖 Lua 的动态类型在运行时实现多态
5. **内置类型扩展**：扩展方法通过元表 `__index` 实现，对同一类型的多次扩展会叠加方法（后续扩展的方法会优先被查找）
6. **隐式 this**：仅在 `struct/class` 体内声明的 `var/let` 字段名可被隐式解析为 `self.field`，局部变量同名时局部变量优先
7. **访问控制**：不支持 `public`/`private`/`protected` 访问修饰符
8. **元组嵌套字面量**：不支持直接嵌套元组字面量 `((1,2), (3,4))`，需通过变量间接嵌套
9. **枚举类型**：支持带参数的枚举构造器、递归枚举、泛型枚举和成员函数
10. **模式匹配**：支持枚举模式、常量模式、通配符模式、类型模式和元组模式，但不支持守卫条件（where）
11. **异常处理**：不支持 `try/catch/finally`，使用 Lua 的 `pcall` 替代
12. **文件模块**：不支持仓颉的 `package`/`import` 模块系统，使用 Lua 的 `require` 替代

## 构建与测试

```bash
# 构建
make

# 运行所有测试
bash run_tests.sh

# 运行单个仓颉文件
./lua example.cj
```

## 项目结构

- `llex.c/h` - 词法分析器，定义仓颉关键字和运算符
- `lparser.c/h` - 语法分析器，实现仓颉语法到 Lua 字节码的编译
- `lbaselib.c` - 基础运行时库，包含类/结构体构造支持、类型扩展、继承链和枚举支持
- `cangjie-tests/` - 仓颉语言特性测试用例（严格仓颉语法）
- `cangjie-tests/ext-features/` - 融合 Lua 动态特性的扩展测试（仓颉语言超集）
- `cangjie-tests/usages/` - 综合应用案例
- `lvm.c` - Lua 虚拟机，执行编译后的字节码

## 参考

- [仓颉语言文档](https://cangjie-lang.cn/docs)
- [Lua 官方网站](https://www.lua.org/)
