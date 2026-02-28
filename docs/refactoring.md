# 改造过程与技术方案文档

## 背景与动机

Lua 语言的官方实现将词法分析器（lexer）、语法分析器（parser）、代码生成器（code generator）与虚拟机（VM）编译为一个整体。这种设计对标准使用场景是合理的，但在以下需求面前暴露出局限性：

1. **嵌入式场景**：在资源受限的设备上，解析器和编译器占用了不必要的代码空间和内存。如果只需执行预编译字节码，前端部分完全是多余的。
2. **多语言前端**：当希望用其他语言（如自定义 DSL、TypeScript 变体等）编译为 Lua 字节码并在 VM 上执行时，Lua 的前端不仅无用，还会引入不必要的依赖。
3. **安全需求**：在某些部署环境中，禁止运行时编译源代码是一项安全要求。独立 VM 从架构层面保证了这一点。
4. **模块化架构**：将 VM 解耦为独立模块，有利于代码的维护、测试和复用。

因此，我们的目标是：**在不修改 VM 核心逻辑的前提下，通过条件编译将 Lua 前端（llex.c、lparser.c、lcode.c）从 VM 中剥离，形成一个可独立编译和链接的 VM 共享库（`libluavm.so`）**。

## 耦合点分析

通过对 Lua 5.5 源码的系统分析，我们发现 VM 核心代码与前端之间存在以下耦合点：

### 耦合点 1：`ldo.c` → `lparser.h`

**位置**：`ldo.c` 第 27 行

```c
#include "lparser.h"
```

**耦合内容**：

- `f_parser()` 函数中调用 `luaY_parser()` 来解析 Lua 源文本。
- `SParser` 结构体包含 `Mbuffer buff`（词法扫描器缓冲区）和 `Dyndata dyd`（解析器动态数据），这两个类型定义在 `llex.h` 和 `lparser.h` 中。
- `luaD_protectedparser()` 函数初始化和释放这些解析器数据结构。

**影响**：这是最主要的耦合点。`ldo.c` 是 VM 的核心调度模块，负责函数调用、保护调用和协程恢复等基本功能。其中的 `luaD_protectedparser` 直接依赖解析器。

### 耦合点 2：`lstate.c` → `llex.h`

**位置**：`lstate.c` 第 23 行

```c
#include "llex.h"
```

**耦合内容**：

- `f_luaopen()` 函数中调用 `luaX_init(L)` 来初始化词法分析器。
- `luaX_init` 的主要作用是将 Lua 保留字（`and`、`break`、`do` 等）预先驻留到字符串表中，并标记为保留字。

**影响**：`lstate.c` 管理 Lua 状态的创建和销毁，是 VM 必需的模块。`luaX_init` 的缺失仅影响保留字字符串不会被预驻留，不影响 VM 的字节码执行能力。

### 耦合点 3：`ldebug.c` → `lcode.h`

**位置**：`ldebug.c` 第 20 行

```c
#include "lcode.h"
```

**耦合内容**：

- 该头文件包含在 `ldebug.c` 中，但经过分析，`ldebug.c` 并未直接使用 `lcode.h` 中定义的任何函数或宏。这是一个历史遗留的冗余包含。

**影响**：移除该包含不影响任何功能。

## 解决方案设计

### 核心策略：`LUA_VM_ONLY` 编译宏

我们引入编译时宏 `LUA_VM_ONLY`，通过条件编译 (`#ifndef LUA_VM_ONLY`) 在不修改原有代码逻辑的前提下隔离前端依赖。

设计原则：

1. **最小侵入**：仅在必要的耦合点添加条件编译指令，不改变任何现有逻辑。
2. **双向兼容**：不定义 `LUA_VM_ONLY` 时，编译行为与原始 Lua 完全一致。
3. **功能完整**：VM 模式保留完整的 C API、标准库和字节码执行能力。
4. **清晰的错误信息**：在 VM-only 模式下尝试加载文本 chunk 时，给出明确的错误提示。

## 具体代码变更

### 变更 1：`ldo.c` —— 核心解耦

这是改造工作的主体，涉及三处条件编译：

#### 1a. 头文件包含守卫

```c
/* ldo.c 第 27 行 */
#ifndef LUA_VM_ONLY
#include "lparser.h"
#endif
```

#### 1b. `SParser` 结构体条件裁剪

```c
struct SParser {  /* data to 'f_parser' */
  ZIO *z;
#ifndef LUA_VM_ONLY
  Mbuffer buff;  /* dynamic structure used by the scanner */
  Dyndata dyd;   /* dynamic structures used by the parser */
#endif
  const char *mode;
  const char *name;
};
```

在 VM-only 模式下，`SParser` 仅保留 `ZIO *z`（输入流）、`mode` 和 `name` 三个字段，体积大幅缩小。`Mbuffer` 和 `Dyndata` 类型定义在 `llex.h` 和 `lparser.h` 中，移除后消除了对前端头文件的依赖。

#### 1c. `f_parser` 函数中的文本解析分支

```c
static void f_parser (lua_State *L, void *ud) {
  LClosure *cl;
  struct SParser *p = cast(struct SParser *, ud);
  const char *mode = p->mode ? p->mode : "bt";
  int c = zgetc(p->z);  /* read first character */
  if (c == LUA_SIGNATURE[0]) {
    /* 二进制 chunk 分支 —— 两种模式下都保留 */
    int fixed = 0;
    if (strchr(mode, 'B') != NULL)
      fixed = 1;
    else
      checkmode(L, mode, "binary");
    cl = luaU_undump(L, p->z, p->name, fixed);
  }
#ifndef LUA_VM_ONLY
  else {
    /* 文本 chunk 分支 —— 仅完整构建保留 */
    checkmode(L, mode, "text");
    cl = luaY_parser(L, p->z, &p->buff, &p->dyd, p->name, c);
  }
#else
  else {
    /* VM-only 模式：拒绝文本 chunk */
    cl = NULL;
    luaO_pushfstring(L,
        "attempt to load a text chunk (no parser available)");
    luaD_throw(L, LUA_ERRSYNTAX);
  }
#endif
  lua_assert(cl->nupvalues == cl->p->sizeupvalues);
  luaF_initupvals(L, cl);
}
```

#### 1d. `luaD_protectedparser` 中的 Dyndata 管理

```c
TStatus luaD_protectedparser (lua_State *L, ZIO *z,
                              const char *name, const char *mode) {
  struct SParser p;
  TStatus status;
  incnny(L);
  p.z = z; p.name = name; p.mode = mode;
#ifndef LUA_VM_ONLY
  /* 初始化解析器动态数据 */
  p.dyd.actvar.arr = NULL; p.dyd.actvar.size = 0;
  p.dyd.gt.arr = NULL; p.dyd.gt.size = 0;
  p.dyd.label.arr = NULL; p.dyd.label.size = 0;
  luaZ_initbuffer(L, &p.buff);
#endif
  status = luaD_pcall(L, f_parser, &p, savestack(L, L->top.p), L->errfunc);
#ifndef LUA_VM_ONLY
  /* 释放解析器动态数据 */
  luaZ_freebuffer(L, &p.buff);
  luaM_freearray(L, p.dyd.actvar.arr, cast_sizet(p.dyd.actvar.size));
  luaM_freearray(L, p.dyd.gt.arr, cast_sizet(p.dyd.gt.size));
  luaM_freearray(L, p.dyd.label.arr, cast_sizet(p.dyd.label.size));
#endif
  decnny(L);
  return status;
}
```

### 变更 2：`lstate.c` —— 词法分析器初始化守卫

```c
/* 头文件包含 */
#ifndef LUA_VM_ONLY
#include "llex.h"
#endif

/* f_luaopen 函数中 */
static void f_luaopen (lua_State *L, void *ud) {
  global_State *g = G(L);
  UNUSED(ud);
  stack_init(L, L);
  init_registry(L, g);
  luaS_init(L);
  luaT_init(L);
#ifndef LUA_VM_ONLY
  luaX_init(L);       /* 仅完整构建时初始化词法分析器 */
#endif
  g->gcstp = 0;
  setnilvalue(&g->nilvalue);
  luai_userstateopen(L);
}
```

移除 `luaX_init` 调用的影响：

- Lua 保留字不会被预驻留为固定字符串。
- 这不影响 VM 执行字节码，因为字节码中不包含保留字——它们已在编译阶段被转换为对应的指令。
- 唯一的潜在影响是：如果用户代码创建了与保留字同名的字符串，这些字符串不会被识别为保留字（但 VM 模式下也不存在需要识别保留字的场景）。

### 变更 3：`ldebug.c` —— 移除冗余包含

```c
/* ldebug.c 第 20 行 */
#ifndef LUA_VM_ONLY
#include "lcode.h"
#endif
```

这是最简单的变更。`ldebug.c` 不使用 `lcode.h` 中的任何符号，守卫的添加仅是为了在 VM-only 编译时不引入不必要的头文件依赖。

### 变更 4：`luaconf.h` —— `LUA_ENV` 定义迁移

`LUA_ENV`（环境上值名称，默认为 `"_ENV"`）原定义在 `llex.h` 中。由于 VM-only 模式不包含 `llex.h`，而 `LUA_ENV` 在 VM 执行过程中可能被引用，因此将其迁移到 `luaconf.h`：

```c
/* luaconf.h */
#if !defined(LUA_ENV)
#define LUA_ENV    "_ENV"
#endif
```

这确保了无论是否包含词法分析器，`LUA_ENV` 宏始终可用。

## 构建系统设计

### CMakeLists.txt 架构

```cmake
# 源文件分组
VM_CORE_SOURCES    # VM 核心：lapi.c, ldo.c, lvm.c, lgc.c, ...
VM_STDLIB_SOURCES  # 标准库：lbaselib.c, lstrlib.c, ...
FRONTEND_SOURCES   # 前端：llex.c, lparser.c, lcode.c

# 目标 1：独立 VM 共享库
add_library(luavm SHARED ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm PRIVATE LUA_VM_ONLY)

# 目标 2：完整 Lua 静态库
add_library(liblua STATIC
    ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES} ${FRONTEND_SOURCES})

# 目标 3：Lua 解释器
add_executable(lua_exe lua.c)
target_link_libraries(lua_exe liblua)

# 目标 4：VM 集成测试
add_executable(test_vm tests/test_vm.c)
target_link_libraries(test_vm luavm)
```

### 文件组织

| 分类 | 文件 | 说明 |
|------|------|------|
| **VM 核心** | `lapi.c`, `ldo.c`, `lvm.c`, `lgc.c`, `lmem.c`, `lobject.c`, `lstate.c`, `lstring.c`, `ltable.c`, `ltm.c`, `lfunc.c`, `ldebug.c`, `ldump.c`, `lundump.c`, `lopcodes.c`, `lctype.c`, `lzio.c` | VM 运行必需 |
| **标准库** | `lauxlib.c`, `lbaselib.c`, `ldblib.c`, `liolib.c`, `lmathlib.c`, `loslib.c`, `ltablib.c`, `lstrlib.c`, `lutf8lib.c`, `loadlib.c`, `lcorolib.c`, `linit.c` | 标准库实现 |
| **前端** | `llex.c`, `lparser.c`, `lcode.c` | 仅完整 Lua 需要 |
| **公共头文件** | `lua.h`, `luaconf.h`, `lualib.h`, `lauxlib.h`, `luavm.h` | 用户可见 API |

## 公共 API 设计：`luavm.h`

`luavm.h` 作为独立 VM 的专用公共接口，设计遵循以下原则：

1. **自包含**：包含 `lua.h`、`lauxlib.h`、`lualib.h`，用户只需 `#include "luavm.h"` 即可使用完整 API。
2. **便利宏**：`luaVM_loadbytecode` 封装了 `luaL_loadbufferx` 的 `mode="b"` 调用。
3. **运行时检测**：`luaVM_hasparser()` 允许编写兼容两种构建模式的代码。
4. **签名常量**：`LUAVM_SIGNATURE` 暴露字节码签名供外部验证。

```c
/* 头文件守卫与包含 */
#ifndef luavm_h
#define luavm_h
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

/* 便利宏：加载字节码 */
#define luaVM_loadbytecode(L, buf, sz, name) \
    luaL_loadbufferx((L), (buf), (sz), (name), "b")

/* 运行时检测解析器可用性 */
static int luaVM_hasparser(lua_State *L);

/* 字节码签名常量 */
#define LUAVM_SIGNATURE  LUA_SIGNATURE

#endif
```

## 测试策略

### 集成测试：`tests/test_vm.c`

`test_vm.c` 链接 `libluavm` 库，验证独立 VM 的核心功能：

| 测试用例 | 验证内容 |
|----------|----------|
| `test_state_creation` | `luaL_newstate` 和 `lua_close` 正常工作 |
| `test_open_libs` | `luaL_openlibs` 成功加载标准库，`print` 函数可用 |
| `test_stack_operations` | 整数、浮点数、字符串、布尔值、nil 的压栈和读取 |
| `test_table_operations` | 表的创建、字段设置和读取 |
| `test_c_function_call` | C 函数压栈、算术操作 |
| `test_load_bytecode` | 加载并执行 `return 42` 字节码，验证返回值 |
| `test_load_hello` | 加载并执行 `print("Hello")` 字节码 |
| `test_reject_text` | VM-only 模式拒绝文本 chunk，完整模式接受 |
| `test_gc` | 垃圾回收器正常运作 |
| `test_coroutine` | 协程创建 |
| `test_error_handling` | 无效字节码加载产生错误 |

### 示例字节码

`samples/` 目录包含预编译的字节码文件，覆盖常见场景：

| 文件 | 说明 |
|------|------|
| `return42.lua` / `.luac` | 简单返回值 |
| `hello.lua` / `.luac` | 标准输出 |
| `arithmetic.lua` / `.luac` | 算术运算 |
| `tables.lua` / `.luac` | 表操作 |
| `strings.lua` / `.luac` | 字符串处理 |
| `closures.lua` / `.luac` | 闭包与上值 |
| `coroutine.lua` / `.luac` | 协程 |
| `fibonacci.lua` / `.luac` | 递归计算 |

### 构建与运行测试

```bash
# CMake 构建
mkdir build && cd build
cmake .. && make test_vm
./test_vm

# 直接编译
gcc -o test_vm tests/test_vm.c -I. -L. -lluavm -lm -ldl
LD_LIBRARY_PATH=. ./test_vm
```

## 改造验证

改造完成后需验证以下要点：

1. **完整 Lua 无回归**：不定义 `LUA_VM_ONLY` 时，`liblua.a` 和 `lua` 解释器行为与改造前完全一致。
2. **VM-only 编译通过**：定义 `LUA_VM_ONLY` 时，仅编译 VM 核心和标准库源文件，不引用任何前端符号。
3. **字节码执行正确**：预编译字节码在独立 VM 中的执行结果与完整 Lua 中一致。
4. **文本 chunk 拒绝**：VM-only 模式下加载文本 chunk 产生明确的 `LUA_ERRSYNTAX` 错误。
5. **标准库完整可用**：所有标准库函数（`print`、`table.sort`、`string.format` 等）在独立 VM 中正常工作。

## 未来方向

### 自定义语言前端

独立 VM 的核心价值在于支持自定义语言前端。开发新前端的步骤：

1. **设计语言语法**：定义词法和语法规则。
2. **实现编译器**：可以用任何语言实现（C、Python、Rust 等），输出符合 Lua 5.5 格式的字节码。
3. **集成运行**：使用 `luaVM_loadbytecode` 加载编译产物并执行。

### 进一步优化

- **裁剪标准库**：对于深度嵌入场景，可以选择性移除不需要的标准库（如 `io`、`os`）。
- **静态链接模式**：提供 `libluavm.a` 静态库目标，消除运行时库依赖。
- **字节码验证器**：在 `luaU_undump` 基础上增加更严格的字节码验证，防止恶意构造的字节码导致 VM 崩溃。
- **JIT 后端**：在独立 VM 架构上集成 JIT 编译器，将热点字节码编译为本地机器码。
