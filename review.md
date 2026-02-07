# 问题发现与修复记录

本文档记录了本次任务中发现的新问题、问题原因分析及修复方案。

---

## 问题 1：多维数组区间索引寄存器冲突

### 问题表现
链式表达式如 `data[0][1..3]` 或 `m.data[1][0..3]` 在运行时报错 `attempt to call a table value (field 'integer index')`，或者返回错误的切片结果（如 `start` 始终为 0）。单层数组区间索引如 `arr[1..3]` 正常工作，通过中间变量 `let tmp = data[0]; tmp[1..3]` 也正常工作。

### 问题原因
在 `suffixedexp` 函数的 `case '['` 分支中，原始代码在最外层调用了 `luaK_exp2anyregup(fs, v)` 来解析数组表达式 `v`。但对于区间操作路径（range slice），后续还会通过 `luaK_exp2nextreg(fs, v)` 再次推入 `v`，导致 `v` 被重复解析。

修复尝试中发现了更深层的问题：当 `v` 是一个 VINDEXI/VINDEXSTR 索引表达式时（如 `m.data[1]`），Lua 编译器的 `luaK_dischargevars` 函数会调用 `freereg(fs, e->u.ind.t)` 释放表寄存器。如果切片辅助函数（`__cangjie_array_slice`）已经被加载到表寄存器之上的寄存器中，`freereg` 会错误地递减 `fs->freereg` 计数器，导致后续寄存器分配覆盖已有值。

具体寄存器冲突场景：
1. `v` = VINDEXI(t=R1, idx=1)，R1 是 `m.data` 的临时寄存器，freereg=2
2. 加载 `__cangjie_array_slice` 到 R2，freereg=3
3. 解析 `v` 时 `freereg(fs, R1)` 发现 R1 >= nvarstack 但 R1 != freereg-1（R1=1, freereg-1=2），断言失败但因 `lua_assert` 在 release 模式下为空操作，freereg 被错误递减为 2
4. 后续 `exp2reg` 将 GETI 结果写入 R2，覆盖了已加载的切片函数

### 修复方案
采用 **先放 arr 后放 fn 再交换** 的策略：
1. 先将 `v`（数组表达式）通过 `luaK_exp2nextreg` 安全解析到寄存器（此时 freereg 正确递增）
2. 再加载切片辅助函数到下一个寄存器
3. 通过三条 `OP_MOVE` 指令交换 arr 和 fn 的寄存器位置，确保 fn 在 base、arr 在 base+1

---

## 问题 2：接口默认方法未编译

### 问题表现
在 `interface` 中定义带方法体的默认实现（如 `func doubleCompute(x: Int64) { return this.compute(x) * 2 }`），实现该接口的类无法继承这些默认方法。

### 问题原因
`interfacestat` 函数在解析接口成员时，对于带方法体的函数声明只是简单地跳过大括号内的 token（通过深度计数跳过），没有实际编译方法体。接口表被创建为空表，没有存储任何方法实现。

### 修复方案
1. 新增 `body_or_abstract()` 解析函数：区分抽象方法声明（无方法体）和默认实现（有方法体）。对有方法体的方法，像普通类方法一样完整编译并存储到接口表中。对抽象方法，仅跳过声明。
2. 重写 `interfacestat` 函数：使用 `body_or_abstract()` 替代原有的 token 跳过逻辑，将编译后的默认方法存储到接口表中。
3. 新增 `__cangjie_apply_interface` 运行时函数：在类/结构体创建后，遍历接口表，将默认方法复制到类表中（仅复制类中未定义的方法）。
4. 在 `structstat` 和 `extendstat` 中追踪接口名称列表，在类创建完成后自动生成 `__cangjie_apply_interface` 调用。

---

## 问题 3：不支持复合赋值运算符

### 问题表现
`a += 5`、`a -= 3` 等复合赋值语法在编译时报语法错误。

### 问题原因
`exprstat` 和 `statlist_autoreturning` 函数中未处理复合赋值语法。当解析到 `a` 后遇到 `+` 时，由于 `+` 不是 `=` 或 `,`，且 `a` 不是 VCALL，直接报语法错误。

### 修复方案
在 `exprstat` 和 `statlist_autoreturning` 中添加复合赋值检测逻辑：
1. 检测当前 token 为 `+`/`-`/`*`/`/` 且 lookahead 为 `=`
2. 将 `x += e` 编译为 `x = x + e`：保存左值表达式，读取当前值，解析右值表达式，执行二元运算，存储回原左值

---

## 问题 4：表达式语句不支持非函数调用

### 问题表现
`logger << "hello"` 等运算符表达式作为语句使用时报语法错误 `syntax error`。

### 问题原因
`exprstat` 函数在非赋值分支中要求表达式必须是 VCALL（函数调用），通过 `check_condition(ls, v.v.k == VCALL, "syntax error")` 强制检查。对于运算符表达式（如 `<<`）产生的结果不是 VCALL，导致报错。

此外，`exprstat` 只调用 `suffixedexp` 而不继续解析二元运算符，因此 `a << b` 中的 `<<` 运算符永远不会被消费。

### 修复方案
1. 在 `exprstat` 的 else 分支中，添加二元运算符继续解析循环（与 `statlist_autoreturning` 类似）
2. 对非 VCALL 表达式，通过 `luaK_exp2nextreg` 求值后丢弃结果（`fs->freereg--`），允许运算符表达式的副作用执行

---

## 问题 5：结构体/类字段默认值未编译

### 问题表现
`class Config { var maxRetries = 3; ... }` 中的默认值 `= 3` 被跳过，实例的字段初始值为 nil 而非 3。

### 问题原因
`structstat` 函数在解析 `var field: Type = expr` 时，对 `= expr` 部分只是调用 `expr(ls, &dummy)` 跳过表达式，未将默认值存储到类表中。

### 修复方案
将字段默认值编译为 `ClassName.field = value` 的赋值语句：
1. 构建 `ClassName.field` 的索引表达式
2. 编译默认值表达式
3. 通过 `luaK_storevar` 将值存储到类表中
实例通过原型链（`__index`）继承默认值。

---

## 问题 6：缺少 Float64 内置方法

### 问题表现
`Float64.GetPI()` 和 `Float64(42)` 类型转换不可用。

### 问题原因
`luaB_extend_type` 运行时函数中没有为 Float64 类型注册内置静态方法和 `__call` 元方法。

### 修复方案
在 `luaB_extend_type` 中为 Float64 类型添加：
1. `GetPI` 静态方法（返回 `M_PI`）
2. `__call` 元方法（支持 `Float64(value)` 类型转换语法）
