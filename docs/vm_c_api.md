# 虚拟机 C 接口文档

## 概述

Lua 5.5 独立虚拟机（`libluavm.so`）是将 Lua VM 执行引擎从 Lua 前端（词法分析器、语法分析器、编译器）中解耦后形成的独立模块。该模块保留了完整的 Lua C API 用于状态管理、栈操作、表访问、函数调用、协程、垃圾回收以及全部标准库，但**不包含**源代码文本解析能力——仅能加载和执行预编译的字节码（二进制 chunk）。

独立 VM 的典型应用场景包括：

- **嵌入式系统**：在资源受限的环境中运行预编译字节码，节省内存和存储空间。
- **多语言前端**：用其他语言（如自定义 DSL）生成 Lua 字节码，交由 VM 执行。
- **安全沙箱**：仅允许执行预审查的字节码，杜绝运行时编译带来的安全风险。
- **分布式执行**：在编译节点生成字节码，在执行节点仅部署轻量级 VM。

## 构建方式

### 使用 CMake 构建

```bash
mkdir build && cd build
cmake ..
make luavm
```

CMake 项目定义了独立的 `luavm` 共享库目标，编译时自动添加 `-DLUA_VM_ONLY` 宏：

```cmake
add_library(luavm SHARED ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm PRIVATE LUA_VM_ONLY)
```

构建产物为 `libluavm.so`（Linux）或 `libluavm.dylib`（macOS），公开头文件包括 `lua.h`、`luaconf.h`、`lualib.h`、`lauxlib.h` 和 `luavm.h`。

### 使用 GCC 直接编译

```bash
# 编译 VM 核心源文件
gcc -shared -fPIC -DLUA_VM_ONLY -DLUA_USE_LINUX -o libluavm.so \
    lapi.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c \
    lmem.c lobject.c lopcodes.c lstate.c lstring.c ltable.c \
    ltm.c lundump.c lvm.c lzio.c \
    lauxlib.c lbaselib.c ldblib.c liolib.c lmathlib.c loslib.c \
    ltablib.c lstrlib.c lutf8lib.c loadlib.c lcorolib.c linit.c \
    -lm -ldl
```

关键编译标志：

| 标志 | 说明 |
|------|------|
| `-DLUA_VM_ONLY` | 启用 VM-only 模式，排除解析器/编译器依赖 |
| `-DLUA_USE_LINUX` | Linux 平台标志（启用 `dlopen` 等） |
| `-DLUA_USE_MACOSX` | macOS 平台标志 |
| `-fPIC` | 生成位置无关代码（共享库必需） |

### 链接应用程序

```bash
gcc -o myapp myapp.c -I/path/to/lua -L/path/to/build -lluavm -lm -ldl
```

运行时需要设置库搜索路径：

```bash
LD_LIBRARY_PATH=/path/to/build ./myapp
```

## 公共头文件 `luavm.h`

`luavm.h` 是独立 VM 的专用公共接口头文件，它包含了所有必要的 Lua 头文件并提供以下便利接口：

### `luaVM_loadbytecode`

```c
#define luaVM_loadbytecode(L, buf, sz, name) \
    luaL_loadbufferx((L), (buf), (sz), (name), "b")
```

加载预编译字节码的便利宏。将 `luaL_loadbufferx` 的 `mode` 参数固定为 `"b"`（仅接受二进制 chunk），成功时返回 `LUA_OK`，将编译后的函数压入栈顶。

### `luaVM_hasparser`

```c
static int luaVM_hasparser(lua_State *L);
```

运行时检测当前构建是否包含文本解析器。在 `LUA_VM_ONLY` 构建中返回 `0`，在完整 Lua 构建中返回 `1`。可用于编写同时兼容两种构建模式的代码。

### `LUAVM_SIGNATURE`

```c
#define LUAVM_SIGNATURE  LUA_SIGNATURE  /* "\x1bLua" */
```

字节码签名常量，等同于 `LUA_SIGNATURE`（`"\x1bLua"`）。可在加载字节码前用于快速验证数据有效性。

## 核心 API 函数参考

独立 VM 支持完整的 Lua C API。以下按功能分类列出关键函数。

### 状态管理

| 函数 | 说明 |
|------|------|
| `lua_State *lua_newstate(lua_Alloc f, void *ud)` | 使用自定义分配器创建新的 Lua 状态 |
| `lua_State *luaL_newstate(void)` | 使用默认分配器创建新的 Lua 状态 |
| `void lua_close(lua_State *L)` | 关闭状态并释放所有资源 |

### 栈操作

| 函数 | 说明 |
|------|------|
| `int lua_gettop(lua_State *L)` | 获取栈顶索引（即元素数量） |
| `void lua_settop(lua_State *L, int index)` | 设置栈顶位置 |
| `void lua_pushvalue(lua_State *L, int index)` | 将指定索引处的值复制到栈顶 |
| `void lua_rotate(lua_State *L, int idx, int n)` | 旋转栈中元素 |
| `void lua_copy(lua_State *L, int fromidx, int toidx)` | 复制值到指定位置 |
| `int lua_checkstack(lua_State *L, int n)` | 确保栈有足够空间 |
| `void lua_pop(lua_State *L, int n)` | 弹出 n 个元素（宏） |

### 压栈操作

| 函数 | 说明 |
|------|------|
| `void lua_pushnil(lua_State *L)` | 压入 nil |
| `void lua_pushinteger(lua_State *L, lua_Integer n)` | 压入整数 |
| `void lua_pushnumber(lua_State *L, lua_Number n)` | 压入浮点数 |
| `const char *lua_pushstring(lua_State *L, const char *s)` | 压入字符串 |
| `const char *lua_pushlstring(lua_State *L, const char *s, size_t len)` | 压入指定长度的字符串 |
| `void lua_pushboolean(lua_State *L, int b)` | 压入布尔值 |
| `void lua_pushcfunction(lua_State *L, lua_CFunction fn)` | 压入 C 函数 |
| `void lua_pushlightuserdata(lua_State *L, void *p)` | 压入轻量用户数据 |

### 类型检查与转换

| 函数 | 说明 |
|------|------|
| `int lua_type(lua_State *L, int index)` | 获取值的类型 |
| `const char *lua_typename(lua_State *L, int tp)` | 获取类型名称字符串 |
| `int lua_isnil(lua_State *L, int index)` | 是否为 nil |
| `int lua_isboolean(lua_State *L, int index)` | 是否为布尔值 |
| `int lua_isinteger(lua_State *L, int index)` | 是否为整数 |
| `int lua_isnumber(lua_State *L, int index)` | 是否为数字 |
| `int lua_isstring(lua_State *L, int index)` | 是否为字符串 |
| `int lua_isfunction(lua_State *L, int index)` | 是否为函数 |
| `int lua_istable(lua_State *L, int index)` | 是否为表 |
| `lua_Integer lua_tointeger(lua_State *L, int index)` | 转换为整数 |
| `lua_Number lua_tonumber(lua_State *L, int index)` | 转换为浮点数 |
| `const char *lua_tostring(lua_State *L, int index)` | 转换为字符串 |
| `int lua_toboolean(lua_State *L, int index)` | 转换为布尔值 |

### 表操作

| 函数 | 说明 |
|------|------|
| `void lua_newtable(lua_State *L)` | 创建新的空表 |
| `void lua_createtable(lua_State *L, int narr, int nrec)` | 预分配空间创建表 |
| `int lua_getfield(lua_State *L, int index, const char *k)` | 获取 `t[k]` |
| `void lua_setfield(lua_State *L, int index, const char *k)` | 设置 `t[k] = v` |
| `int lua_gettable(lua_State *L, int index)` | 获取 `t[key]`（key 在栈顶） |
| `void lua_settable(lua_State *L, int index)` | 设置 `t[key] = v` |
| `int lua_rawget(lua_State *L, int index)` | 原始表访问（不触发元方法） |
| `void lua_rawset(lua_State *L, int index)` | 原始表设置 |
| `int lua_rawgeti(lua_State *L, int index, lua_Integer n)` | 原始整数键访问 |
| `void lua_rawseti(lua_State *L, int index, lua_Integer n)` | 原始整数键设置 |
| `int lua_getglobal(lua_State *L, const char *name)` | 获取全局变量 |
| `void lua_setglobal(lua_State *L, const char *name)` | 设置全局变量 |

### 函数调用

| 函数 | 说明 |
|------|------|
| `void lua_call(lua_State *L, int nargs, int nresults)` | 调用函数（无保护） |
| `int lua_pcall(lua_State *L, int nargs, int nresults, int msgh)` | 保护模式调用函数 |
| `void lua_pushcfunction(lua_State *L, lua_CFunction fn)` | 压入 C 函数供调用 |

`lua_pcall` 在出错时返回错误码并将错误消息压入栈顶：

| 返回值 | 说明 |
|--------|------|
| `LUA_OK` (0) | 调用成功 |
| `LUA_ERRRUN` | 运行时错误 |
| `LUA_ERRMEM` | 内存分配错误 |
| `LUA_ERRERR` | 错误处理函数自身出错 |

### 协程

| 函数 | 说明 |
|------|------|
| `lua_State *lua_newthread(lua_State *L)` | 创建新协程 |
| `int lua_resume(lua_State *L, lua_State *from, int nargs, int *nresults)` | 启动/恢复协程 |
| `int lua_yieldk(lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k)` | 挂起协程 |
| `int lua_status(lua_State *L)` | 获取协程状态 |

### 垃圾回收控制

```c
int lua_gc(lua_State *L, int what, ...);
```

| `what` 参数 | 说明 |
|-------------|------|
| `LUA_GCCOLLECT` | 执行一次完整的垃圾回收周期 |
| `LUA_GCSTOP` | 停止垃圾回收 |
| `LUA_GCRESTART` | 重启垃圾回收 |
| `LUA_GCCOUNT` | 返回已用内存（KB） |
| `LUA_GCCOUNTB` | 返回已用内存的余数（字节） |
| `LUA_GCSTEP` | 执行一步增量回收 |
| `LUA_GCISRUNNING` | 检查回收器是否在运行 |
| `LUA_GCINC` | 切换为增量模式 |
| `LUA_GCGEN` | 切换为分代模式 |

### 错误处理

| 函数 | 说明 |
|------|------|
| `int lua_error(lua_State *L)` | 抛出错误（使用栈顶值作为错误对象） |
| `int luaL_error(lua_State *L, const char *fmt, ...)` | 格式化错误消息并抛出 |
| `void lua_warning(lua_State *L, const char *msg, int tocont)` | 发出警告 |

## 字节码加载

在 VM-only 模式下，加载 Lua 代码的唯一方式是通过预编译字节码。

### 标准加载方式

```c
int status = luaL_loadbufferx(L, bytecode_buf, bytecode_len, "chunkname", "b");
```

`mode` 参数设为 `"b"` 表示仅接受二进制格式。如果传入文本 chunk，将返回 `LUA_ERRSYNTAX` 错误，错误消息为：

```
attempt to load a text chunk (no parser available)
```

### 使用便利宏

```c
int status = luaVM_loadbytecode(L, bytecode_buf, bytecode_len, "chunkname");
```

### 从文件加载字节码

VM-only 模式下不能直接使用 `luaL_loadfile`（默认 mode 为 `"bt"`，含文本模式）。需要先将 `.luac` 文件读入内存，然后使用 `luaVM_loadbytecode` 加载：

```c
/* 读取字节码文件到内存 */
FILE *f = fopen("script.luac", "rb");
fseek(f, 0, SEEK_END);
size_t len = ftell(f);
fseek(f, 0, SEEK_SET);
char *buf = malloc(len);
fread(buf, 1, len, f);
fclose(f);

/* 加载并执行 */
int status = luaVM_loadbytecode(L, buf, len, "script");
free(buf);
```

### 生成字节码

字节码由完整的 Lua 编译器生成。常用方式：

```bash
# 使用 luac 命令行工具
luac -o script.luac script.lua

# 使用 string.dump 在 Lua 中生成
lua -e 'f = loadfile("script.lua"); io.open("script.luac","wb"):write(string.dump(f)):close()'
```

## 标准库

独立 VM 包含完整的 Lua 标准库。

### 批量加载所有标准库

```c
luaL_openlibs(L);
```

### 单独加载各标准库

| 函数 | 库名 | 说明 |
|------|------|------|
| `luaopen_base` | `_G` | 基础库（`print`、`type`、`error`等） |
| `luaopen_coroutine` | `coroutine` | 协程库 |
| `luaopen_table` | `table` | 表操作库 |
| `luaopen_io` | `io` | I/O 库 |
| `luaopen_os` | `os` | 操作系统库 |
| `luaopen_string` | `string` | 字符串库 |
| `luaopen_math` | `math` | 数学库 |
| `luaopen_utf8` | `utf8` | UTF-8 库 |
| `luaopen_debug` | `debug` | 调试库 |
| `luaopen_package` | `package` | 包管理库 |

注意：基础库中的 `load` 和 `dofile` 函数在 VM-only 模式下仅支持二进制 chunk。

## 限制

在 VM-only 构建中，以下功能不可用：

1. **无法加载文本 chunk**：`luaL_loadstring`、`luaL_dostring` 或使用 `mode="t"` 的加载函数将失败。
2. **无法运行时编译**：`load()` Lua 函数不能接受源代码字符串（仅能接受预编译字节码）。
3. **无词法分析器初始化**：`luaX_init` 不会被调用，因此保留字不会被驻留为固定字符串（不影响 VM 正常执行）。

## 完整使用示例

```c
#include <stdio.h>
#include <stdlib.h>
#include "luavm.h"

/* 读取字节码文件 */
static unsigned char *read_file(const char *path, size_t *len) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    *len = (size_t)ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char *buf = malloc(*len);
    fread(buf, 1, *len, f);
    fclose(f);
    return buf;
}

int main(void) {
    /* 1. 创建 Lua 状态 */
    lua_State *L = luaL_newstate();
    if (!L) {
        fprintf(stderr, "无法创建 Lua 状态\n");
        return 1;
    }

    /* 2. 加载标准库 */
    luaL_openlibs(L);

    /* 3. 检查是否为 VM-only 模式 */
    printf("解析器可用: %s\n", luaVM_hasparser(L) ? "是" : "否");

    /* 4. 加载字节码 */
    size_t len;
    unsigned char *bytecode = read_file("script.luac", &len);
    if (!bytecode) {
        fprintf(stderr, "无法读取字节码文件\n");
        lua_close(L);
        return 1;
    }

    int status = luaVM_loadbytecode(L, (const char *)bytecode, len, "script");
    free(bytecode);

    if (status != LUA_OK) {
        fprintf(stderr, "加载失败: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    /* 5. 执行字节码 */
    status = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (status != LUA_OK) {
        fprintf(stderr, "执行失败: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    /* 6. 读取返回值 */
    int nresults = lua_gettop(L);
    for (int i = 1; i <= nresults; i++) {
        printf("结果 %d: %s\n", i, luaL_tolstring(L, i, NULL));
        lua_pop(L, 1);  /* 弹出 luaL_tolstring 产生的字符串 */
    }

    /* 7. 关闭状态 */
    lua_close(L);
    return 0;
}
```

编译运行：

```bash
gcc -o myapp myapp.c -I. -L. -lluavm -lm -ldl
LD_LIBRARY_PATH=. ./myapp
```

## 错误码参考

| 常量 | 值 | 说明 |
|------|---|------|
| `LUA_OK` | 0 | 成功 |
| `LUA_YIELD` | 1 | 协程挂起 |
| `LUA_ERRRUN` | 2 | 运行时错误 |
| `LUA_ERRSYNTAX` | 3 | 语法/加载错误（VM-only 模式下加载文本 chunk 时） |
| `LUA_ERRMEM` | 4 | 内存分配错误 |
| `LUA_ERRERR` | 5 | 错误处理函数本身出错 |
