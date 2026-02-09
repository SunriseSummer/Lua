# 问题修复日志

## 问题描述

使用 `Parser` 类解析数字时，代码执行报错：
```
attempt to index a nil value (field '?')
```

错误出现在类方法中通过链式索引访问二维数组时。

## 根因分析

### Bug：编译器寄存器冲突

**文件**：`src/compiler/lparser.c` — `suffixedops()` 函数

在编译链式索引表达式 `obj[a][func_call()]` 时，当 `obj` 是类字段（通过隐式 `self` 访问）时，编译器会出现寄存器冲突。

具体原因：在 `case '['` 分支中，原有代码先调用 `subexpr()` 解析索引键表达式（可能是函数调用如 `Int64(Rune(text[i]))`），然后才通过 `luaK_exp2anyregup()` 将表（table）表达式 `v` 物化到寄存器中。然而 `subexpr()` 解析函数调用时生成的代码可能会复用 `v`（VINDEXED 形式）所引用的寄存器，导致这些寄存器中的值被覆盖，后续对 `v` 的读取得到错误的值。

**修复方案**：在调用 `subexpr()` 解析键表达式**之前**，先将 `v` 物化到寄存器中（调用 `luaK_exp2anyregup(fs, v)`），确保表达式结果安全存储在专用寄存器中，不会被后续代码生成覆盖。

## Rune 类型实现

将 Rune 实现为**独立的运行时类型**（使用带元表的 Lua 表），与整型和字符串严格区分。

### Rune 字面量语法

- **`r'x'` / `r"x"`**：Rune 字面量，编译时生成 `Rune(code_point)` 调用，创建 Rune 类型实例
- **`'x'` / `"x"`**：字符串字面量

### Rune 运行时表示

Rune 值在运行时是带有共享元表的 Lua 表 `{code_point}`，元表提供：
- `__tostring`：返回对应的 UTF-8 字符串（如 `tostring(r'A')` = "A"）
- `__eq`：按码点值比较相等性
- `__lt` / `__le`：按码点值比较大小

### 类型语义

- `Rune(65) != 65`（Rune 和整型是不同类型）
- `Rune(65) == Rune(65)` == `r'A'`（相同码点的 Rune 值相等）
- `Rune(Rune(65)) == Rune(65)`（Rune 的 Rune 转换是恒等操作）
- `type(r'A')` = "Rune"

### 类型转换规则

- `Int64(Rune)` → 提取整型 Unicode 码点值（`Int64(r'A')` = 65）
- `Int64(String)` → 将表示数字的字符串解析为整数（`Int64("0")` = 0），解析失败报错
- `String(Rune)` → 转为对应的字符串（`String(r'A')` = "A"）
- `Rune(integer)` → 通过码点值构造 Rune 实例（`Rune(65)` = `r'A'`）
- `Rune(string)` → 将单字符字符串转为 Rune 实例（`Rune("A")` = `r'A'`），长度不为 1 则报错
- `Rune(Rune)` → 恒等操作

## 修复涉及的文件

| 文件 | 修改内容 |
|------|----------|
| `src/compiler/lparser.c` | `suffixedops()` 中 `[` 分支：在 `subexpr` 前先 discharge 表达式；`simpleexp()` / `primaryexp()` 中 `TK_RUNE` 处理 |
| `src/compiler/llex.c` | `r'x'` / `r"x"` 编译为 `TK_RUNE` 令牌（携带码点整数） |
| `src/include/llex.h` | 新增 `TK_RUNE` 令牌类型 |
| `src/libs/lbaselib_cj.c` | Rune 类型实现（元表、`is_rune`、`push_rune`）；`Int64` / `String` / `Rune` 转换函数 |
| `src/include/lbaselib_cj.h` | `luaB_rune_init` / `luaB_is_rune` 声明 |
| `src/libs/lbaselib.c` | `type()` 函数识别 Rune 类型；`luaopen_base` 初始化 Rune 元表 |

## 新增/更新测试

| 文件 | 说明 |
|------|------|
| `cangjie-tests/54_rune_type.cj` | Rune 独立类型测试（构造、比较、转换） |
| `cangjie-tests/75_chained_index_funcall.cj` | 链式索引 + 函数调用键的边界测试 |
| `cangjie-tests/76_int64_codepoint.cj` | Int64/Rune 转换规则测试 |
| `cangjie-tests/usages/number_parser.cj` | 有限状态机数字解析器综合应用 |
| `cangjie-tests/diagnosis/08_type_conversion_errors.cj` | 类型转换错误测试 |
| `cangjie-tests/diagnosis/12_rune_type_errors.cj` | Rune 编译时错误测试 |
