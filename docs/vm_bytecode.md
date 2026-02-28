# 虚拟机字节码定义文档

## 概述

Lua 5.5 虚拟机采用基于寄存器的指令集架构，每条指令为固定的 32 位无符号整数。指令集包含 85 条操作码，涵盖数据移动、算术运算、位运算、比较跳转、函数调用/返回、表操作、循环控制等全部虚拟机操作。

本文档详细描述了指令格式、完整操作码列表以及二进制 chunk（字节码文件）的序列化格式。所有定义均来自源代码中的 `src/lopcodes.h`、`src/lundump.h` 和 `src/lundump.c`。

## 指令格式

### 32 位指令布局

所有指令的低 7 位为操作码（opcode），高位为操作数。Lua 5.5 定义了 6 种指令格式：

```
         3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0
         1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
iABC          C(8)     |      B(8)     |k|     A(8)      |   Op(7)     |
ivABC         vC(10)     |     vB(6)   |k|     A(8)      |   Op(7)     |
iABx                Bx(17)               |     A(8)      |   Op(7)     |
iAsBx              sBx (signed)(17)      |     A(8)      |   Op(7)     |
iAx                           Ax(25)                     |   Op(7)     |
isJ                           sJ (signed)(25)            |   Op(7)     |
```

### 格式说明

| 格式 | 操作数 | 说明 |
|------|--------|------|
| **iABC** | A(8), B(8), C(8), k(1) | 三操作数格式，含 1 位 k 标志 |
| **ivABC** | A(8), vB(6), vC(10), k(1) | 变体三操作数格式（vB 较短，vC 较长） |
| **iABx** | A(8), Bx(17) | 双操作数格式，Bx 为 17 位无符号扩展操作数 |
| **iAsBx** | A(8), sBx(17) | 双操作数格式，sBx 为 17 位有符号操作数 |
| **iAx** | Ax(25) | 单操作数格式，Ax 为 25 位扩展操作数 |
| **isJ** | sJ(25) | 跳转指令格式，sJ 为 25 位有符号偏移量 |

> 前缀 `v` 表示"variant"（变体），`s` 表示"signed"（有符号），`x` 表示"extended"（扩展）。

### 字段大小与范围

| 字段 | 位数 | 位置 | 最大值 |
|------|------|------|--------|
| Op | 7 | 0 | 127 |
| A | 8 | 7 | 255 |
| k | 1 | 15 | 1 |
| B | 8 | 16 | 255 |
| vB | 6 | 16 | 63 |
| C | 8 | 24 | 255 |
| vC | 10 | 22 | 1023 |
| Bx | 17 | 15 | 131071 |
| sBx | 17 | 15 | -65536 ~ 65535 |
| Ax | 25 | 7 | 33554431 |
| sJ | 25 | 7 | ±16777215 |

有符号字段使用偏移编码（excess-K）：实际值 = 无符号值 - K，其中 K = 对应无符号最大值的一半（向下取整）。

### 操作数约定

- **R[x]**：寄存器 x（栈中位置 x）
- **K[x]**：常量表中索引 x 处的常量
- **RK(x)**：若 k 标志为 1 则为 K[x]，否则为 R[x]
- **UpValue[x]**：上值表中索引 x 处的上值
- **pc**：程序计数器

## 完整操作码列表

Lua 5.5 共定义 85 条操作码（`OP_MOVE` = 0 至 `OP_EXTRAARG` = 84）。

### 数据加载与移动

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_MOVE` | iABC | A B | `R[A] := R[B]` |
| `OP_LOADI` | iAsBx | A sBx | `R[A] := sBx`（加载有符号整数立即数） |
| `OP_LOADF` | iAsBx | A sBx | `R[A] := (lua_Number)sBx`（加载浮点数） |
| `OP_LOADK` | iABx | A Bx | `R[A] := K[Bx]`（加载常量） |
| `OP_LOADKX` | iABx | A | `R[A] := K[extra arg]`（扩展常量加载，下一条指令为 EXTRAARG） |
| `OP_LOADFALSE` | iABC | A | `R[A] := false` |
| `OP_LFALSESKIP` | iABC | A | `R[A] := false; pc++`（加载 false 并跳过下一条指令） |
| `OP_LOADTRUE` | iABC | A | `R[A] := true` |
| `OP_LOADNIL` | iABC | A B | `R[A], R[A+1], ..., R[A+B] := nil` |

### 上值操作

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_GETUPVAL` | iABC | A B | `R[A] := UpValue[B]` |
| `OP_SETUPVAL` | iABC | A B | `UpValue[B] := R[A]` |

### 表访问

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_GETTABUP` | iABC | A B C | `R[A] := UpValue[B][K[C]:shortstring]` |
| `OP_GETTABLE` | iABC | A B C | `R[A] := R[B][R[C]]` |
| `OP_GETI` | iABC | A B C | `R[A] := R[B][C]`（整数键访问） |
| `OP_GETFIELD` | iABC | A B C | `R[A] := R[B][K[C]:shortstring]`（字符串键访问） |
| `OP_SETTABUP` | iABC | A B C | `UpValue[A][K[B]:shortstring] := RK(C)` |
| `OP_SETTABLE` | iABC | A B C | `R[A][R[B]] := RK(C)` |
| `OP_SETI` | iABC | A B C | `R[A][B] := RK(C)`（整数键设置） |
| `OP_SETFIELD` | iABC | A B C | `R[A][K[B]:shortstring] := RK(C)` |
| `OP_NEWTABLE` | ivABC | A vB vC k | `R[A] := {}`（创建新表；vB 为哈希部分大小的 log2+1，vC 为数组部分大小） |
| `OP_SELF` | iABC | A B C | `R[A+1] := R[B]; R[A] := R[B][K[C]:shortstring]`（方法调用准备） |
| `OP_SETLIST` | ivABC | A vB vC k | `R[A][vC+i] := R[A+i], 1 <= i <= vB`（批量设置列表元素） |

### 算术运算——立即数与常量形式

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_ADDI` | iABC | A B sC | `R[A] := R[B] + sC`（加有符号整数立即数） |
| `OP_ADDK` | iABC | A B C | `R[A] := R[B] + K[C]:number` |
| `OP_SUBK` | iABC | A B C | `R[A] := R[B] - K[C]:number` |
| `OP_MULK` | iABC | A B C | `R[A] := R[B] * K[C]:number` |
| `OP_MODK` | iABC | A B C | `R[A] := R[B] % K[C]:number` |
| `OP_POWK` | iABC | A B C | `R[A] := R[B] ^ K[C]:number` |
| `OP_DIVK` | iABC | A B C | `R[A] := R[B] / K[C]:number` |
| `OP_IDIVK` | iABC | A B C | `R[A] := R[B] // K[C]:number`（整除） |

### 位运算——常量形式

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_BANDK` | iABC | A B C | `R[A] := R[B] & K[C]:integer` |
| `OP_BORK` | iABC | A B C | `R[A] := R[B] \| K[C]:integer` |
| `OP_BXORK` | iABC | A B C | `R[A] := R[B] ~ K[C]:integer` |

### 移位运算——立即数形式

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_SHLI` | iABC | A B sC | `R[A] := sC << R[B]` |
| `OP_SHRI` | iABC | A B sC | `R[A] := R[B] >> sC` |

### 算术运算——寄存器形式

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_ADD` | iABC | A B C | `R[A] := R[B] + R[C]` |
| `OP_SUB` | iABC | A B C | `R[A] := R[B] - R[C]` |
| `OP_MUL` | iABC | A B C | `R[A] := R[B] * R[C]` |
| `OP_MOD` | iABC | A B C | `R[A] := R[B] % R[C]` |
| `OP_POW` | iABC | A B C | `R[A] := R[B] ^ R[C]` |
| `OP_DIV` | iABC | A B C | `R[A] := R[B] / R[C]` |
| `OP_IDIV` | iABC | A B C | `R[A] := R[B] // R[C]` |

### 位运算——寄存器形式

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_BAND` | iABC | A B C | `R[A] := R[B] & R[C]` |
| `OP_BOR` | iABC | A B C | `R[A] := R[B] \| R[C]` |
| `OP_BXOR` | iABC | A B C | `R[A] := R[B] ~ R[C]` |
| `OP_SHL` | iABC | A B C | `R[A] := R[B] << R[C]` |
| `OP_SHR` | iABC | A B C | `R[A] := R[B] >> R[C]` |

### 元方法调用

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_MMBIN` | iABC | A B C | 对 `R[A]` 和 `R[B]` 调用 C 号元方法 |
| `OP_MMBINI` | iABC | A sB C k | 对 `R[A]` 和有符号立即数 sB 调用 C 号元方法；k 指示操作数是否翻转 |
| `OP_MMBINK` | iABC | A B C k | 对 `R[A]` 和 `K[B]` 调用 C 号元方法；k 指示操作数是否翻转 |

> 元方法指令紧跟在对应的算术/位运算指令之后。如果运算成功，则跳过元方法指令；否则由元方法指令调用相应的元方法。

### 一元运算

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_UNM` | iABC | A B | `R[A] := -R[B]`（取负） |
| `OP_BNOT` | iABC | A B | `R[A] := ~R[B]`（按位取反） |
| `OP_NOT` | iABC | A B | `R[A] := not R[B]`（逻辑非） |
| `OP_LEN` | iABC | A B | `R[A] := #R[B]`（取长度） |

### 字符串操作

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_CONCAT` | iABC | A B | `R[A] := R[A].. ... ..R[A + B - 1]`（连接 B 个值） |

### 控制流——跳转

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_JMP` | isJ | sJ | `pc += sJ`（无条件跳转） |
| `OP_CLOSE` | iABC | A | 关闭 `R[A]` 及以上的所有上值 |
| `OP_TBC` | iABC | A | 标记变量 A 为"待关闭"（to-be-closed） |

### 比较指令

所有比较指令在条件不满足时跳过下一条指令（该指令必须为跳转指令），`k` 指定测试接受的条件值。

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_EQ` | iABC | A B k | `if ((R[A] == R[B]) ~= k) then pc++` |
| `OP_LT` | iABC | A B k | `if ((R[A] < R[B]) ~= k) then pc++` |
| `OP_LE` | iABC | A B k | `if ((R[A] <= R[B]) ~= k) then pc++` |
| `OP_EQK` | iABC | A B k | `if ((R[A] == K[B]) ~= k) then pc++` |
| `OP_EQI` | iABC | A sB k | `if ((R[A] == sB) ~= k) then pc++` |
| `OP_LTI` | iABC | A sB k | `if ((R[A] < sB) ~= k) then pc++` |
| `OP_LEI` | iABC | A sB k | `if ((R[A] <= sB) ~= k) then pc++` |
| `OP_GTI` | iABC | A sB k | `if ((R[A] > sB) ~= k) then pc++` |
| `OP_GEI` | iABC | A sB k | `if ((R[A] >= sB) ~= k) then pc++` |

### 测试指令

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_TEST` | iABC | A k | `if (not R[A] == k) then pc++` |
| `OP_TESTSET` | iABC | A B k | `if (not R[B] == k) then pc++ else R[A] := R[B]`（用于短路求值） |

### 函数调用与返回

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_CALL` | iABC | A B C | `R[A], ..., R[A+C-2] := R[A](R[A+1], ..., R[A+B-1])`；B=0 表示参数到栈顶，C=0 表示返回值数量可变 |
| `OP_TAILCALL` | iABC | A B C k | `return R[A](R[A+1], ..., R[A+B-1])`（尾调用）；k 指示是否需要关闭上值 |
| `OP_RETURN` | iABC | A B C k | `return R[A], ..., R[A+B-2]`；B=0 表示返回到栈顶；k 指示是否需要关闭上值 |
| `OP_RETURN0` | iABC | — | `return`（无返回值的优化返回） |
| `OP_RETURN1` | iABC | A | `return R[A]`（单返回值的优化返回） |

### 循环控制

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_FORLOOP` | iABx | A Bx | 更新数值 for 循环计数器；若循环继续则 `pc -= Bx` |
| `OP_FORPREP` | iABx | A Bx | 检查数值 for 循环值并准备计数器；若不执行则 `pc += Bx + 1` |
| `OP_TFORPREP` | iABx | A Bx | 为 `R[A+3]` 创建上值；`pc += Bx`（泛型 for 循环准备） |
| `OP_TFORCALL` | iABC | A C | `R[A+4], ..., R[A+3+C] := R[A](R[A+1], R[A+2])`（调用泛型 for 循环迭代器） |
| `OP_TFORLOOP` | iABx | A Bx | `if R[A+2] ~= nil then { R[A] = R[A+2]; pc -= Bx }`（泛型 for 循环继续判断） |

### 闭包与变长参数

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_CLOSURE` | iABx | A Bx | `R[A] := closure(KPROTO[Bx])`（创建闭包） |
| `OP_VARARG` | iABC | A B C k | `R[A], ..., R[A+C-2] = varargs`；C=0 表示数量可变；k 表示函数有变长参数表 |
| `OP_GETVARG` | iABC | A B C | `R[A] := R[B][R[C]]`（R[B] 为变长参数参数） |
| `OP_VARARGPREP` | iAx | — | 调整变长参数 |

### 错误处理与扩展

| 操作码 | 格式 | 操作数 | 描述 |
|--------|------|--------|------|
| `OP_ERRNNIL` | iABx | A Bx | 若 `R[A] ~= nil` 则抛出错误（`K[Bx-1]` 为全局变量名）；Bx=0 表示名称不可用 |
| `OP_EXTRAARG` | iAx | Ax | 为前一条指令提供额外的扩展参数 |

## 二进制 Chunk 格式

二进制 chunk 是 `string.dump` 输出和 `luac` 编译器产生的序列化格式，由 `luaU_undump` 函数加载。

### 总体结构

```
+------------------+
|     头部信息      |
+------------------+
|   上值数量 (1B)   |
+------------------+
|   主函数原型      |
+------------------+
```

### 头部格式

| 偏移 | 大小 | 内容 | 说明 |
|------|------|------|------|
| 0 | 4 | `\x1bLua` | 签名（`LUA_SIGNATURE`） |
| 4 | 1 | `0x55` | 版本号（主版本×16 + 次版本：5×16+5=0x55） |
| 5 | 1 | `0x00` | 格式号（`LUAC_FORMAT`，0 = 官方格式） |
| 6 | 6 | `\x19\x93\r\n\x1a\n` | 数据校验字符串（`LUAC_DATA`） |
| 12 | sizeof(int) | `-0x5678` | int 大小与字节序校验（`LUAC_INT`） |
| 12+n | sizeof(Instruction) | `0x12345678` | 指令大小校验（`LUAC_INST`） |
| ... | sizeof(lua_Integer) | `-0x5678` | lua_Integer 大小校验 |
| ... | sizeof(lua_Number) | `-370.5` | lua_Number 大小校验（`LUAC_NUM`） |

校验机制确保加载的字节码与当前平台的数据类型大小、字节序完全匹配。

### 函数原型（Proto）

每个函数原型按以下顺序序列化：

```
+------------------+
|  源文件名 (string) |  -- 主函数才有实际值，内嵌函数可能为 NULL
+------------------+
|  linedefined     |  -- 起始行号
|  lastlinedefined |  -- 结束行号
+------------------+
|  numparams       |  -- 固定参数数量
|  flag            |  -- 函数标志（是否有变长参数等）
|  maxstacksize    |  -- 最大栈大小
+------------------+
|  指令数组 (code)  |  -- n 条 32 位指令
+------------------+
|  常量数组         |  -- 常量值列表
+------------------+
|  上值描述数组     |  -- 上值描述符
+------------------+
|  内嵌函数原型数组  |  -- 递归嵌套的子函数原型
+------------------+
|  调试信息         |  -- 行号表、局部变量名等
+------------------+
```

### 常量类型

常量数组中的每个常量以类型标签开头，后跟数据：

| 类型标签 | 说明 | 数据格式 |
|----------|------|----------|
| `LUA_VNIL` | nil | 无额外数据 |
| `LUA_VFALSE` | false | 无额外数据 |
| `LUA_VTRUE` | true | 无额外数据 |
| `LUA_VNUMINT` | 整数 | `lua_Integer`（平台相关大小） |
| `LUA_VNUMFLT` | 浮点数 | `lua_Number`（平台相关大小） |
| `LUA_VSHRSTR` | 短字符串 | 长度 + 字节数据 |
| `LUA_VLNGSTR` | 长字符串 | 长度 + 字节数据 |

### 上值描述

每个上值描述包含：

| 字段 | 大小 | 说明 |
|------|------|------|
| `instack` | 1 字节 | 是否在栈上（1 = 局部变量，0 = 外层上值） |
| `idx` | 1 字节 | 栈索引或外层上值索引 |
| `kind` | 1 字节 | 变量类型标志 |

### 调试信息

调试信息包含以下部分（可通过 `string.dump(f, true)` 的 strip 参数移除）：

1. **行号信息**（lineinfo）：每条指令对应的行号偏移（相对编码）
2. **绝对行号**（abslineinfo）：每隔一定指令数存储的绝对行号参考点
3. **局部变量信息**（locvars）：变量名、起始/结束 PC
4. **上值名称**（upvalnames）：上值对应的变量名

## 字节码签名与验证

### 签名常量

```c
#define LUA_SIGNATURE  "\x1bLua"    /* 4 字节 */
```

每个有效的 Lua 二进制 chunk 都以此 4 字节签名开头。第一个字节 `0x1b`（ESC）确保字节码文件不会被误当作文本文件处理。

### 验证流程

`luaU_undump` 加载字节码时执行以下验证：

1. **签名检查**：验证前 4 字节为 `\x1bLua`
2. **版本检查**：确认版本号匹配（Lua 5.5 = `0x55`）
3. **格式检查**：确认格式号为 0（官方格式）
4. **数据完整性**：验证 `LUAC_DATA` 校验字节
5. **平台兼容性**：通过写入并回读特定数值来验证：
   - `int` 大小和字节序
   - `Instruction` 大小（必须为 32 位）
   - `lua_Integer` 大小和字节序
   - `lua_Number` 大小和字节序

### 使用 `LUAVM_SIGNATURE` 预验证

```c
static int is_valid_bytecode(const char *buf, size_t len) {
    if (len < 4) return 0;
    return memcmp(buf, LUAVM_SIGNATURE, strlen(LUAVM_SIGNATURE)) == 0;
}
```

## 指令属性位掩码

每条操作码都有一个 8 位属性掩码（定义在 `luaP_opmodes` 数组中）：

| 位 | 说明 |
|----|------|
| 0-2 | 指令格式（OpMode 枚举值） |
| 3 | 指令设置寄存器 A |
| 4 | 指令为测试指令（下一条指令必须为跳转） |
| 5 | 指令使用前一条指令设置的 `L->top`（当 B=0 时） |
| 6 | 指令为下一条指令设置 `L->top`（当 C=0 时） |
| 7 | 指令为元方法指令 |

查询宏：

```c
getOpMode(m)   /* 获取指令格式 */
testAMode(m)   /* 是否设置寄存器 A */
testTMode(m)   /* 是否为测试指令 */
testITMode(m)  /* 是否使用 top（输入） */
testOTMode(m)  /* 是否设置 top（输出） */
testMMMode(m)  /* 是否为元方法指令 */
```

## 指令操作数访问宏

```c
GET_OPCODE(i)      /* 获取操作码 */
GETARG_A(i)        /* 获取 A 操作数 */
GETARG_B(i)        /* 获取 B 操作数（iABC 格式） */
GETARG_vB(i)       /* 获取 vB 操作数（ivABC 格式） */
GETARG_sB(i)       /* 获取有符号 B */
GETARG_C(i)        /* 获取 C 操作数 */
GETARG_vC(i)       /* 获取 vC 操作数（ivABC 格式） */
GETARG_sC(i)       /* 获取有符号 C */
GETARG_Bx(i)       /* 获取 Bx 操作数（iABx 格式） */
GETARG_sBx(i)      /* 获取有符号 sBx（iAsBx 格式） */
GETARG_Ax(i)       /* 获取 Ax 操作数（iAx 格式） */
GETARG_sJ(i)       /* 获取有符号 sJ（isJ 格式） */
GETARG_k(i)        /* 获取 k 标志位 */
```
