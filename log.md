# 问题修复日志

## 问题描述

使用 `Parser` 类解析数字时，代码执行报错：
```
attempt to index a nil value (field '?')
```

错误出现在类方法中通过 `states[s][Int64(text[i])]` 访问二维数组时。

## 根因分析

该问题由**两个独立的 bug** 共同导致：

### Bug 1：编译器寄存器冲突（核心 bug）

**文件**：`src/compiler/lparser.c` — `suffixedops()` 函数

在编译链式索引表达式 `obj[a][func_call()]` 时，当 `obj` 是类字段（通过隐式 `self` 访问）时，编译器会出现寄存器冲突。

具体原因：在 `case '['` 分支中，原有代码先调用 `subexpr()` 解析索引键表达式（可能是函数调用如 `Int64(text[i])`），然后才通过 `luaK_exp2anyregup()` 将表（table）表达式 `v` 物化到寄存器中。然而 `subexpr()` 解析函数调用时生成的代码可能会复用 `v`（VINDEXED 形式）所引用的寄存器，导致这些寄存器中的值被覆盖，后续对 `v` 的读取得到错误的值。

**修复方案**：在调用 `subexpr()` 解析键表达式**之前**，先将 `v` 物化到寄存器中（调用 `luaK_exp2anyregup(fs, v)`），确保表达式结果安全存储在专用寄存器中，不会被后续代码生成覆盖。

### Bug 2：Int64 单字符字符串转换语义

**文件**：`src/libs/lbaselib_cj.c` — `luaB_cangjie_int64()` 函数

原有实现中 `Int64(string)` 对所有字符串都优先尝试数值解析（`lua_stringtonumber`），这导致 `Int64("1")` 返回数字 `1` 而非字符 `'1'` 的 Unicode 码点 `49`。

在仓颉语言中，`Int64(Rune)` 应返回字符的 Unicode 码点，`Int64(String)` 应解析数字字符串。由于本解释器中 Rune 和单字符 String 在运行时是同一类型（Lua 字符串），需要通过长度来区分：

- **单个 UTF-8 字符**：视为 Rune，返回 Unicode 码点（如 `Int64('0')` → 48，`Int64('A')` → 65）
- **多字符字符串**：解析为数字（如 `Int64("123")` → 123）

**修复方案**：调整 `luaB_cangjie_int64()` 中的优先级顺序——先检查是否为单个 UTF-8 字符（使用 `utf8_decode_single`），若是则直接返回码点；否则再尝试数值解析。

## 修复涉及的文件

| 文件 | 修改内容 |
|------|----------|
| `src/compiler/lparser.c` | `suffixedops()` 中 `[` 分支：在 `subexpr` 前先 discharge 表达式 |
| `src/libs/lbaselib_cj.c` | `luaB_cangjie_int64()`：单字符优先返回码点 |
| `cangjie-tests/53_type_conversions.cj` | 更新 `Int64('0')` 和 `Int64("0")` 的期望值 |
| `cangjie-tests/62_type_conv_boundary.cj` | 更新 `Int64("0")` 的期望值 |

## 新增测试

| 文件 | 说明 |
|------|------|
| `cangjie-tests/75_chained_index_funcall.cj` | 链式索引 + 函数调用键的边界测试 |
| `cangjie-tests/76_int64_codepoint.cj` | Int64 单字符码点转换测试 |
| `cangjie-tests/usages/number_parser.cj` | 有限状态机数字解析器综合应用 |
