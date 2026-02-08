# 任务日志 (Task Log)

## 发现的问题与修复

### 1. 取模运算符语义不符 (Modulo Operator Semantics)

**问题**: Lua 的 `%` 运算符使用 floored division（向下取整除法），导致 `-7 % 3 = 2`；而仓颉语言规范要求使用 truncated division（截断除法），即 `-7 % 3 = -1`（与 C/Java/Swift 一致）。

**修复**:
- `src/core/runtime/lvm.c`: 移除 `luaV_mod()` 中的 floored division 修正代码（原来会在结果符号与除数不同时加上除数值）
- `src/include/llimits.h`: 简化 `luai_nummod` 宏，直接使用 `fmod()` 结果（`fmod` 本身就是 truncated modulo）

**验证**: `-7 % 3 = -1`, `7 % -3 = 1`, `-7 % -3 = -1` — 全部符合仓颉规范。

---

### 2. `??` 合并运算符链式调用寄存器分配错误

**问题**: `a ?? b ?? c ?? 0` 这样的链式 `??` 表达式返回错误的值。根本原因是代码生成器在每次迭代中将结果放入递增的寄存器，但外层 `let/var` 赋值只从第一个寄存器取值，导致中间结果丢失。

**分析**:
- `expr()` 中的 `??` 处理循环，每次迭代生成 `__cangjie_coalesce(left, right)` 调用
- 第一次调用结果在寄存器 R，但第二次迭代时 `result_reg` 被重新计算为 R+1
- 外层赋值期望值在 R 位置，实际值却在 R+1 或更高位置

**修复**: 在 `src/compiler/lparser.c` 的 `expr()` 函数中：
- 在进入 while 循环前固定 `result_reg`（结果寄存器）
- 每次迭代后将调用结果 OP_MOVE 回 `result_reg`
- 重置 `freereg` 为 `result_reg + 1`，保证所有迭代共享同一结果位置

---

## 解释器优化方案

### 已完成的优化

#### 代码拆分提升可维护性

**lparser.c** 从 6705 行拆分为三个文件：
- `lparser.c` (~3990 行): 核心解析器（词法工具、变量管理、表达式解析、语句分发）
- `lparser_cj_types.c` (~1640 行): 仓颉类型定义解析（struct、class、interface、extend、enum）
- `lparser_cj_match.c` (~1120 行): 仓颉模式匹配和表达式形式（match、if 表达式、block 表达式）

使用 `#include` 技术保持所有 `static` 函数可见性不变，零运行时开销。

### 新增测试覆盖

| 测试文件 | 覆盖内容 |
|---------|---------|
| 40_edge_cases.cj | 负数、零值、大数、取模、双重否定、运算符优先级、变量遮蔽 |
| 41_string_edge_cases.cj | 空字符串插值、方法调用插值、数组访问插值、字符串比较 |
| 42_class_edge_cases.cj | 深层继承链、多态数组分发、多接口实现、静态方法 |
| 43_enum_match_edge_cases.cj | 多构造器枚举、字符串模式匹配、Option 链式合并、枚举方法 |
| 44_lambda_closure_edge_cases.cj | 共享闭包变量、高阶函数组合、递归 lambda、数组存储 lambda |
| 45_array_range_edge_cases.cj | 空数组、混合类型、范围切片、for-in 迭代 |
| diagnosis/05_advanced_errors.cj | match 语法错误、类型重定义、运行时类型错误 |

### 潜在的后续优化方向

1. **整数除法语义**: 仓颉的整数除法 `10 / 3` 应该返回 `3`（整数），当前返回 `3.3333`（浮点数）。可通过在 VM 层面区分整数除法和浮点除法来解决。

2. **类型注解中的函数类型**: `Array<(Int64, Int64) -> Int64>` 类型注解在 `->` 处解析失败。需要增强 `skip_type_annotation()` 对箭头返回类型的处理。

3. **立即调用 Lambda**: `{ => 42 }()` 语法（IIFE）不被支持，因为 `}` 后的 `()` 不被识别为函数调用。可在 `simpleexp()` 或 `suffixedexp()` 中添加支持。

4. **lbaselib_cj.c 拆分**: 该文件 1282 行，可按功能拆分为 OOP 运行时、Option 类型支持、数组操作等模块。
