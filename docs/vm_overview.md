# 虚拟机原理和用法概述

## 设计哲学

Lua 5.5 虚拟机采用**基于寄存器**的指令集架构，这与许多传统虚拟机（如 JVM、CPython）的基于栈的设计形成对比。基于寄存器的设计使得 Lua VM 具有以下优势：

- **更少的指令数量**：操作数直接寻址寄存器，避免了大量 push/pop 操作。
- **更低的指令分派开销**：每条指令完成更多工作，减少解释器循环的迭代次数。
- **更高效的数据访问**：操作数编码在指令中，减少了内存访问次数。

虚拟机的"寄存器"实际上是 Lua 栈的一部分——每个函数调用帧（CallInfo）拥有自己的寄存器窗口，通过栈偏移实现。参数传递和返回值仍然通过栈进行，结合了寄存器机和栈机的优点。

## 架构概览

### lua_State —— 线程状态

`lua_State` 是 Lua VM 的核心数据结构，代表一个执行线程（协程）。每个 `lua_State` 包含：

```
lua_State
├── stack          -- 值栈（寄存器数组）
├── top            -- 栈顶指针（第一个空闲位置）
├── ci             -- 当前 CallInfo（调用帧）
├── base_ci        -- 基础 CallInfo（C 调用者帧）
├── openupval      -- 打开的上值链表
├── status         -- 线程状态码
├── nCcalls        -- C 调用深度计数器
├── hook           -- 调试钩子函数
└── errfunc        -- 错误处理函数索引
```

所有协程共享同一个 `global_State`（通过 `G(L)` 宏访问），其中包含全局资源：字符串表、GC 状态、内存分配器等。

### CallInfo 链 —— 调用帧管理

`CallInfo` 结构描述一次函数调用的执行上下文，所有活跃的 `CallInfo` 形成双向链表：

```
base_ci ←→ ci_1 ←→ ci_2 ←→ ... ←→ ci_n (= L->ci)
```

每个 `CallInfo` 包含：

| 字段 | 说明 |
|------|------|
| `func` | 被调用函数在栈中的位置 |
| `top` | 此函数的栈顶限制 |
| `previous` / `next` | 链表指针 |
| `u.l.savedpc` | Lua 函数的保存程序计数器 |
| `u.l.trap` | 是否有调试陷阱（trace hooks） |
| `u.c.k` | C 函数的延续函数（用于 yield 恢复） |
| `u.c.ctx` | 延续上下文 |
| `callstatus` | 调用状态标志 |

### 栈布局

对于一个 Lua 函数调用 `f(a, b, c)`，栈布局如下：

```
ci->func   ci->func+1   ci->func+2   ci->func+3   ...
   |          |            |            |
   v          v            v            v
+-------+--------+--------+--------+--------+--------+
|  f    |  a     |  b     |  c     | local1 | local2 | ...
+-------+--------+--------+--------+--------+--------+
         R[0]     R[1]     R[2]     R[3]     R[4]
```

函数对象位于 `ci->func` 指向的栈位置，参数从 `R[0]` 开始，本地变量紧随其后。寄存器索引直接对应栈偏移。

### 上值（Upvalue）机制

上值是 Lua 实现闭包的核心机制，允许内部函数访问外部函数的局部变量：

- **开放上值（open）**：指向仍在栈上的变量，通过 `UpVal` 链表管理。
- **关闭上值（closed）**：当外部函数返回时，变量值被复制到 `UpVal` 结构体内部，上值指向该副本。

`OP_CLOSE` 指令负责关闭指定寄存器以上的所有上值，`OP_TBC` 标记"待关闭"变量（Lua 5.4+ 的 to-be-closed 特性）。

## 关键子系统

### 内存管理（lmem.c/lmem.h）

Lua 的所有内存分配通过统一的分配器接口进行：

```c
typedef void *(*lua_Alloc)(void *ud, void *ptr, size_t osize, size_t nsize);
```

核心内存操作由 `luaM_realloc_` 函数统一处理，提供以下语义：

| `ptr` | `nsize` | 操作 |
|-------|---------|------|
| NULL | > 0 | 分配新内存块 |
| 非NULL | 0 | 释放内存块 |
| 非NULL | > 0 | 重新分配（调整大小） |

内存分配失败时触发 GC 紧急回收。若 GC 后仍无法满足，抛出内存错误。

### 垃圾回收器（lgc.c/lgc.h）

Lua 5.5 支持两种 GC 模式：

**增量模式（Incremental）**

将标记-清扫周期分成小步骤与程序交替执行，避免长时间停顿：

| 阶段 | 状态常量 | 说明 |
|------|----------|------|
| 传播 | `GCSpropagate` | 遍历并标记可达对象 |
| 原子 | `GCSatomic` | 不可中断的最终标记步骤 |
| 清扫 | `GCSswpallgc` ~ `GCSswpend` | 回收不可达对象 |
| 终结 | `GCScallfin` | 调用 `__gc` 元方法 |
| 暂停 | `GCSpause` | 等待下一个周期 |

**分代模式（Generational）**

基于"大部分对象早亡"的假设，将对象分为新/老两代，频繁回收新代对象：

- **次要回收（minor collection）**：仅回收新生代对象。
- **主要回收（major collection）**：退化为完整的标记-清扫，回收所有对象。

GC 使用三色标记（白、灰、黑）算法，通过写屏障（barrier）维护不变量。

### 字符串驻留（lstring.c/lstring.h）

Lua 对短字符串（长度 ≤ `LUAI_MAXSHORTLEN`，通常为 40 字节）实施**驻留**（interning）：

- 所有短字符串存储在全局哈希表 `global_State.strt` 中。
- 相同内容的短字符串只保留一份，实现 O(1) 等值比较。
- 字符串一旦创建即不可变。

长字符串不驻留，各自独立存储，使用惰性计算的哈希值。

### 表实现（ltable.c/ltable.h）

Lua 的表是关联数组与序列数组的混合体，内部分为两部分：

- **数组部分**：连续整数键（1 到 n）的值存储在 C 数组中，O(1) 访问。
- **哈希部分**：其他键使用开放寻址哈希表，大小始终为 2 的幂。

哈希碰撞通过链式方法解决——碰撞节点链接到同一桶的链表中，但所有节点都存储在哈希数组内部（无额外分配）。

表的 `alimit` 字段记录数组部分的大小，其值可能是实际大小，也可能是 2 的幂近似值（通过标志位区分）。

### 元方法（ltm.c/ltm.h）

Lua 5.5 支持 25 种元方法，通过 `TMS` 枚举定义：

| 元方法 | 触发条件 |
|--------|----------|
| `__index` | 表中找不到键时 |
| `__newindex` | 设置表中不存在的键时 |
| `__gc` | 对象被垃圾回收时 |
| `__len` | `#` 操作符 |
| `__eq` | `==` 比较 |
| `__add`, `__sub`, `__mul`, `__mod`, `__pow`, `__div`, `__idiv` | 算术运算 |
| `__band`, `__bor`, `__bxor`, `__shl`, `__shr` | 位运算 |
| `__unm` | 一元取负 |
| `__bnot` | 按位取反 |
| `__lt`, `__le` | 有序比较 |
| `__concat` | 字符串连接 |
| `__call` | 函数调用 |
| `__close` | 变量作用域结束时 |

元方法名在 VM 初始化时被预先驻留为固定字符串，存储在 `global_State.tmname` 数组中。

## 执行模型

### 指令分派：`luaV_execute`

`luaV_execute`（定义在 `lvm.c`）是 VM 的核心执行循环。函数签名为：

```c
void luaV_execute(lua_State *L, CallInfo *ci);
```

执行流程：

```
luaV_execute(L, ci)
│
├── 获取指令：i = *pc++
├── 解码操作码：GET_OPCODE(i)
├── 分派执行：
│   ├── 方式1: 跳转表（GCC computed goto，更快）
│   └── 方式2: switch-case（通用兼容方式）
├── 执行操作码对应的操作
└── 返回循环起点（或退出）
```

Lua 5.5 通过 `LUA_USE_JUMPTABLE` 宏和外部跳转表文件 `ljumptab.h` 支持 computed goto 优化。在 GCC/Clang 编译器下，每条指令的分派只需一次间接跳转，比 `switch` 语句更高效。

关键内部宏：

| 宏 | 说明 |
|----|------|
| `vmfetch()` | 取指令并解码 A 操作数 |
| `vmdispatch(o)` | 根据操作码分派 |
| `vmcase(l)` | 操作码 case 标签 |
| `vmbreak` | 跳到下一条指令 |

### 函数调用：`luaD_call`

函数调用通过 `luaD_call`（`ldo.c`）统一处理：

1. **准备阶段**：创建新的 `CallInfo`，设置栈帧。
2. **分派调用**：
   - C 函数：直接调用 `lua_CFunction`，返回值数量由返回值指定。
   - Lua 函数：递归进入 `luaV_execute`。
3. **返回处理**：调整栈，恢复前一个 `CallInfo`。

### 保护调用：`luaD_pcall`

`lua_pcall` 的底层实现使用 `luaD_pcall`，通过 `setjmp/longjmp` 实现错误恢复：

```
luaD_pcall
├── 保存恢复点（保存栈位置、errfunc 等）
├── setjmp 设置跳转点
├── 调用目标函数
├── 若出错 → longjmp 跳回
│   ├── 恢复栈状态
│   ├── 关闭需要关闭的上值
│   └── 压入错误消息
└── 返回状态码
```

## 字节码加载

### `luaU_undump` 加载流程

`luaU_undump`（`lundump.c`）负责将二进制 chunk 反序列化为内存中的函数原型（`Proto`）：

```c
LClosure *luaU_undump(lua_State *L, ZIO *Z, const char *name, int fixed);
```

加载步骤：

1. **头部验证**：检查签名、版本、格式、平台兼容性。
2. **读取上值数量**：主函数的上值数（通常为 1，即 `_ENV`）。
3. **递归加载函数原型**：
   - 函数元数据（参数数、栈大小、标志）
   - 指令数组
   - 常量数组（nil、布尔、数字、字符串）
   - 上值描述符
   - 嵌套子函数原型（递归）
   - 调试信息（行号、变量名等，可选）
4. **创建闭包**：将 `Proto` 包装为 `LClosure`，初始化上值。

`fixed` 参数控制是否使用固定内存模式（不移动数据），对应 `luaL_loadbufferx` 的 `"B"` mode。

### 字节码验证

`luaU_undump` 在加载过程中执行多重验证：

- 签名和版本号匹配
- 数据类型大小兼容
- 字节序一致
- 常量类型标签有效
- 指令数组大小合理

任何验证失败都会产生错误消息并终止加载。

## 与其他语言前端的集成

独立 VM 的设计目标之一是支持多语言前端。要为此 VM 开发新的语言前端，需要：

### 1. 生成兼容的字节码

前端编译器必须生成符合 Lua 5.5 二进制 chunk 格式的字节码文件：

- 正确的头部（签名、版本、平台参数）
- 有效的函数原型结构
- 合法的操作码序列

### 2. 遵守 VM 约定

- **寄存器分配**：合理分配寄存器，不超过 `MAX_FSTACK`（255）。
- **上值管理**：正确设置上值描述符，第一个上值通常为 `_ENV`（环境表）。
- **元方法指令**：算术/比较操作后必须跟随对应的 `OP_MMBIN*` 指令。
- **常量池**：常量索引在有效范围内，类型标签正确。

### 3. 使用 VM 的 C API

```c
/* 从自定义编译器获取字节码 */
unsigned char *bytecode = my_compiler_compile(source, &size);

/* 加载到 VM */
lua_State *L = luaL_newstate();
luaL_openlibs(L);
int status = luaVM_loadbytecode(L, (const char *)bytecode, size, "my_source");

/* 执行 */
if (status == LUA_OK)
    lua_pcall(L, 0, LUA_MULTRET, 0);

lua_close(L);
```

### 4. 可选：注册自定义 C 库

通过 `lua_pushcfunction` 和 `lua_setglobal` 可以向 VM 注册自定义的 C 函数，扩展 VM 的内置功能。

## 性能考量

### 指令分派

- 使用 computed goto（`-DLUA_USE_JUMPTABLE`）可提升约 15-20% 的解释器性能。
- 编译时使用 `-O2` 优化级别能显著提升 VM 性能。

### 内存效率

- 独立 VM（不含解析器/编译器）的代码体积比完整 Lua 小约 30-40%。
- 短字符串驻留减少了重复字符串的内存开销。
- 表的混合数组/哈希设计在大部分使用场景中接近最优。

### GC 调优

- **增量模式**适合对延迟敏感的应用（如游戏），可通过 `lua_gc(L, LUA_GCINC, pause, stepmul, stepsize)` 调整参数。
- **分代模式**适合有大量长寿命对象的应用，可通过 `lua_gc(L, LUA_GCGEN, minormul, majormul)` 调整参数。

### 字节码优化

VM 性能很大程度上取决于字节码质量。Lua 编译器已包含多种优化：

- 常量折叠（`OP_ADDK`、`OP_SUBK` 等常量形式指令）
- 立即数操作（`OP_ADDI`、`OP_SHLI` 等）
- 优化返回（`OP_RETURN0`、`OP_RETURN1`）
- 尾调用优化（`OP_TAILCALL`）
- 针对常见模式的特化指令（`OP_GETI`、`OP_GETFIELD`、`OP_SELF`）
