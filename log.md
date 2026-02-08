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

具体原因：在 `case '['` 分支中，原有代码先调用 `subexpr()` 解析索引键表达式（可能是函数调用如 `text[i].toRune()`），然后才通过 `luaK_exp2anyregup()` 将表（table）表达式 `v` 物化到寄存器中。然而 `subexpr()` 解析函数调用时生成的代码可能会复用 `v`（VINDEXED 形式）所引用的寄存器，导致这些寄存器中的值被覆盖，后续对 `v` 的读取得到错误的值。

**修复方案**：在调用 `subexpr()` 解析键表达式**之前**，先将 `v` 物化到寄存器中（调用 `luaK_exp2anyregup(fs, v)`），确保表达式结果安全存储在专用寄存器中，不会被后续代码生成覆盖。

## Rune 语法规则重构

严格约束 Rune 字面量语法：

- **`r'x'` / `r"x"`**：Rune 字面量，编译时直接转为整数码点（如 `r'A'` = 65，`r'0'` = 48）
- **`'x'` / `"x"`**：字符串字面量，行为一致

### Int64 转换规则

- `Int64(String)`：优先尝试数值解析（`Int64("0")` = 0，`Int64("123")` = 123）；解析失败则返回单字符码点（`Int64("A")` = 65）
- `Int64(Rune)`：Rune 字面量编译为整数，`Int64` 直接透传（`Int64(r'0')` = 48）

### `Rune()` 双向转换函数

- `Rune(integer)` → 将码点转为 UTF-8 字符串（如 `Rune(65)` = "A"）
- `Rune(string)` → 将单字符字符串转为码点整数（如 `Rune("0")` = 48）
- 空字符串报错："Rune() cannot convert empty string"
- 多字符字符串报错："Rune() requires a single-character string"

## 修复涉及的文件

| 文件 | 修改内容 |
|------|----------|
| `src/compiler/lparser.c` | `suffixedops()` 中 `[` 分支：在 `subexpr` 前先 discharge 表达式；`:Rune` 类型标注对字符串字面量报错 |
| `src/compiler/llex.c` | `r'x'` / `r"x"` 编译为 `TK_INT` 整数码点 |
| `src/libs/lbaselib_cj.c` | `Int64` 恢复为数值优先；`Rune()` 支持字符串到码点转换 |

## 新增/更新测试

| 文件 | 说明 |
|------|------|
| `cangjie-tests/75_chained_index_funcall.cj` | 链式索引 + 函数调用键的边界测试 |
| `cangjie-tests/76_int64_codepoint.cj` | Int64/Rune 转换规则测试 |
| `cangjie-tests/54_rune_type.cj` | Rune 类型测试（r'x' 为整数码点） |
| `cangjie-tests/usages/number_parser.cj` | 有限状态机数字解析器综合应用 |
