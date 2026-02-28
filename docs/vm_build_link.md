# 独立虚拟机编译构建与链接指南

## 概述

本文档介绍如何编译构建 Lua 5.5 独立虚拟机（`libluavm`），以及如何在 C 项目中引用和链接该库（支持动态库和静态库两种方式）。最后给出完整的示例代码，演示如何从 C 程序加载 `.luac` 字节码文件并调用 VM 执行。

---

## 1. 编译构建独立 VM 库

### 1.1 源文件分类

独立 VM 排除了前端（词法分析、语法分析、代码生成）的源文件，仅包含以下模块：

| 分类 | 源文件 |
|------|--------|
| **VM 核心** | `src/lapi.c` `src/lctype.c` `src/ldebug.c` `src/ldo.c` `src/ldump.c` `src/lfunc.c` `src/lgc.c` `src/lmem.c` `src/lobject.c` `src/lopcodes.c` `src/lstate.c` `src/lstring.c` `src/ltable.c` `src/ltm.c` `src/lundump.c` `src/lvm.c` `src/lzio.c` |
| **标准库** | `src/lauxlib.c` `src/lbaselib.c` `src/ldblib.c` `src/liolib.c` `src/lmathlib.c` `src/loslib.c` `src/ltablib.c` `src/lstrlib.c` `src/lutf8lib.c` `src/loadlib.c` `src/lcorolib.c` `src/linit.c` |
| **排除（前端）** | `src/llex.c` `src/lparser.c` `src/lcode.c` |

需要的头文件（公开 API）：`lua.h`、`luaconf.h`、`lauxlib.h`、`lualib.h`、`luavm.h`。

### 1.2 使用 CMake 构建

项目已提供 `CMakeLists.txt`，内含独立 VM 的动态库目标 `luavm` 和静态库目标 `luavm_static`：

```bash
# 创建构建目录
mkdir build && cd build

# 配置
cmake ..

# 仅编译 VM 动态库
make luavm

# 仅编译 VM 静态库
make luavm_static

# 编译全部目标（含 VM 动态库、VM 静态库、完整静态库、解释器、测试）
make
```

CMake 中对应的目标定义：

```cmake
# 动态库目标（-DLUA_VM_ONLY 自动添加）
add_library(luavm SHARED ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm PRIVATE LUA_VM_ONLY)

# 静态库目标（-DLUA_VM_ONLY 自动添加，输出文件名为 libluavm.a）
add_library(luavm_static STATIC ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm_static PRIVATE LUA_VM_ONLY)
set_target_properties(luavm_static PROPERTIES OUTPUT_NAME luavm)
```

构建成功后，当前目录会生成：

| 产物 | 说明 |
|------|------|
| `libluavm.so` / `libluavm.dylib` | 独立 VM 动态库 |
| `libluavm.a` | 独立 VM 静态库 |
| `liblua.a` | 包含前端的完整 Lua 静态库 |
| `lua` | 完整 Lua 解释器 |
| `test_vm` | VM 集成测试程序（链接动态库） |
| `test_vm_static` | VM 集成测试程序（链接静态库） |

### 1.3 使用 GCC 直接编译

#### 编译动态库（`.so`）

```bash
gcc -std=c99 -O2 -fPIC -shared \
    -DLUA_VM_ONLY -DLUA_USE_LINUX \
    -o libluavm.so \
    src/lapi.c src/lctype.c src/ldebug.c src/ldo.c src/ldump.c src/lfunc.c src/lgc.c \
    src/lmem.c src/lobject.c src/lopcodes.c src/lstate.c src/lstring.c src/ltable.c \
    src/ltm.c src/lundump.c src/lvm.c src/lzio.c \
    src/lauxlib.c src/lbaselib.c src/ldblib.c src/liolib.c src/lmathlib.c src/loslib.c \
    src/ltablib.c src/lstrlib.c src/lutf8lib.c src/loadlib.c src/lcorolib.c src/linit.c \
    -lm -ldl
```

#### 编译静态库（`.a`）

```bash
# 1. 编译所有 VM 对象文件
gcc -std=c99 -O2 -DLUA_VM_ONLY -DLUA_USE_LINUX -c \
    src/lapi.c src/lctype.c src/ldebug.c src/ldo.c src/ldump.c src/lfunc.c src/lgc.c \
    src/lmem.c src/lobject.c src/lopcodes.c src/lstate.c src/lstring.c src/ltable.c \
    src/ltm.c src/lundump.c src/lvm.c src/lzio.c \
    src/lauxlib.c src/lbaselib.c src/ldblib.c src/liolib.c src/lmathlib.c src/loslib.c \
    src/ltablib.c src/lstrlib.c src/lutf8lib.c src/loadlib.c src/lcorolib.c src/linit.c

# 2. 打包为静态库
ar rcs libluavm.a *.o

# 3. 清理对象文件
rm -f *.o
```

#### 关键编译标志说明

| 标志 | 说明 |
|------|------|
| `-DLUA_VM_ONLY` | **必需**。启用 VM-only 模式，排除解析器/编译器依赖 |
| `-DLUA_USE_LINUX` | Linux 平台推荐，启用 `dlopen`、`readline` 等 POSIX 特性 |
| `-fPIC` | 编译动态库时必需，生成位置无关代码 |
| `-shared` | 生成共享库（动态库） |
| `-lm` | 链接数学库（`math.h`） |
| `-ldl` | 链接动态加载库（`dlopen` 等，Linux 需要） |

#### macOS 注意事项

```bash
# macOS 使用 -dynamiclib 代替 -shared，产物后缀为 .dylib
gcc -std=c99 -O2 -fPIC -dynamiclib \
    -DLUA_VM_ONLY -DLUA_USE_MACOSX \
    -o libluavm.dylib \
    src/lapi.c src/lctype.c src/ldebug.c src/ldo.c src/ldump.c src/lfunc.c src/lgc.c \
    src/lmem.c src/lobject.c src/lopcodes.c src/lstate.c src/lstring.c src/ltable.c \
    src/ltm.c src/lundump.c src/lvm.c src/lzio.c \
    src/lauxlib.c src/lbaselib.c src/ldblib.c src/liolib.c src/lmathlib.c src/loslib.c \
    src/ltablib.c src/lstrlib.c src/lutf8lib.c src/loadlib.c src/lcorolib.c src/linit.c \
    -lm
```

---

## 2. 链接 VM 库

### 2.1 链接动态库

```bash
# 编译用户程序，链接 libluavm.so
gcc -std=c99 -o myapp myapp.c -I/path/to/lua/headers -L/path/to/lib -lluavm -lm -ldl

# 运行时需要设置库搜索路径（或将 .so 安装到系统路径）
LD_LIBRARY_PATH=/path/to/lib ./myapp
```

**安装到系统路径（可选）：**

```bash
# 使用 CMake 安装
cd build && sudo make install

# 或手动复制
sudo cp libluavm.so /usr/local/lib/
sudo cp lua.h luaconf.h lauxlib.h lualib.h luavm.h /usr/local/include/luavm/
sudo ldconfig
```

安装后无需 `LD_LIBRARY_PATH`，直接编译链接即可：

```bash
gcc -std=c99 -o myapp myapp.c -I/usr/local/include/luavm -lluavm -lm -ldl
```

### 2.2 链接静态库

```bash
# 编译用户程序，链接 libluavm.a（静态链接，无运行时依赖）
gcc -std=c99 -o myapp myapp.c -I/path/to/lua/headers -L/path/to/lib -lluavm -lm -ldl -static
```

或直接指定静态库路径：

```bash
gcc -std=c99 -o myapp myapp.c -I/path/to/lua/headers /path/to/libluavm.a -lm -ldl
```

静态链接的优势是生成的可执行文件不依赖外部 `.so`，适合分发和嵌入式部署。

---

## 3. 完整使用示例

以下示例演示一个 C 程序如何链接独立 VM 动态库，加载 `.luac` 字节码文件并执行。

### 3.1 示例 C 代码：`run_bytecode.c`

```c
/*
** run_bytecode.c
** 示例：使用独立 Lua VM 加载并执行 .luac 字节码文件
**
** 编译（动态库）：
**   gcc -std=c99 -o run_bytecode run_bytecode.c -Isrc -L. -lluavm -lm -ldl
**
** 运行：
**   LD_LIBRARY_PATH=. ./run_bytecode samples/hello.luac
**   LD_LIBRARY_PATH=. ./run_bytecode samples/fibonacci.luac
*/

#include <stdio.h>
#include <stdlib.h>
#include "luavm.h"

/* 从文件读取全部内容到内存缓冲区 */
static char *read_file(const char *path, size_t *out_len) {
    FILE *f = fopen(path, "rb");
    long len;
    char *buf;

    if (!f) {
        fprintf(stderr, "Error: cannot open file '%s'\n", path);
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    len = ftell(f);
    fseek(f, 0, SEEK_SET);

    buf = (char *)malloc((size_t)len);
    if (!buf) {
        fprintf(stderr, "Error: out of memory\n");
        fclose(f);
        return NULL;
    }

    if (fread(buf, 1, (size_t)len, f) != (size_t)len) {
        fprintf(stderr, "Error: failed to read file '%s'\n", path);
        free(buf);
        fclose(f);
        return NULL;
    }

    fclose(f);
    *out_len = (size_t)len;
    return buf;
}

int main(int argc, char *argv[]) {
    lua_State *L;
    char *bytecode;
    size_t bc_len;
    int status;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file.luac> [args...]\n", argv[0]);
        return 1;
    }

    /* 1. 读取字节码文件 */
    bytecode = read_file(argv[1], &bc_len);
    if (!bytecode) return 1;

    /* 2. 创建 Lua 状态 */
    L = luaL_newstate();
    if (!L) {
        fprintf(stderr, "Error: failed to create Lua state\n");
        free(bytecode);
        return 1;
    }

    /* 3. 打开标准库（print, string, table, math 等） */
    luaL_openlibs(L);

    /* 4. 加载字节码（mode="b" 表示仅接受二进制格式） */
    status = luaVM_loadbytecode(L, bytecode, bc_len, argv[1]);
    free(bytecode);  /* 字节码已加载到 VM 内部，可以释放外部缓冲区 */

    if (status != LUA_OK) {
        fprintf(stderr, "Load error: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    /* 5. 执行字节码（保护调用） */
    status = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (status != LUA_OK) {
        fprintf(stderr, "Runtime error: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    /* 6. 输出返回值（如果有） */
    int nresults = lua_gettop(L);
    if (nresults > 0) {
        printf("Return values (%d):\n", nresults);
        for (int i = 1; i <= nresults; i++) {
            printf("  [%d] %s = %s\n", i,
                   luaL_typename(L, i),
                   luaL_tolstring(L, i, NULL));
            lua_pop(L, 1);  /* pop the string from luaL_tolstring */
        }
    }

    /* 7. 关闭 Lua 状态 */
    lua_close(L);
    return 0;
}
```

### 3.2 编译和运行示例

#### 使用动态库

```bash
# 假设 Lua 源码根目录为当前目录，已编译 libluavm.so

# 编译示例程序
gcc -std=c99 -o run_bytecode run_bytecode.c -Isrc -L. -lluavm -lm -ldl

# 先生成字节码（使用完整版 Lua 编译源码）
./lua -e "string.dump(assert(loadfile('samples/hello.lua')))" > /dev/null
# 或使用已有的 .luac 文件

# 执行字节码
LD_LIBRARY_PATH=. ./run_bytecode samples/hello.luac
# 输出：Hello from Lua VM!

LD_LIBRARY_PATH=. ./run_bytecode samples/fibonacci.luac
# 输出：Return values (1):
#         [1] integer = 55

LD_LIBRARY_PATH=. ./run_bytecode samples/arithmetic.luac
# 输出：Return values (6):
#         [1] integer = 30
#         [2] integer = -10
#         [3] integer = 200
#         [4] number = 0.5
#         [5] integer = 0
#         [6] integer = 10
```

#### 使用静态库

```bash
# 假设已编译 libluavm.a

# 编译示例程序（静态链接，不依赖外部 .so）
gcc -std=c99 -o run_bytecode run_bytecode.c -Isrc libluavm.a -lm -ldl

# 直接运行，无需 LD_LIBRARY_PATH
./run_bytecode samples/hello.luac
```

### 3.3 更多使用场景示例

#### 场景 A：从内存中加载字节码

如果字节码已嵌入到 C 程序中（如通过 `xxd -i` 生成的数组），可以直接加载：

```c
/* bytecode_data.h — 由 xxd -i samples/return42.luac 生成 */
extern unsigned char samples_return42_luac[];
extern unsigned int samples_return42_luac_len;

/* 在主程序中直接加载 */
status = luaVM_loadbytecode(L,
    (const char *)samples_return42_luac,
    samples_return42_luac_len,
    "return42");
```

生成嵌入头文件的命令：

```bash
xxd -i samples/return42.luac > bytecode_data.h
```

#### 场景 B：调用字节码中定义的 Lua 函数

```c
/* 加载包含函数定义的字节码 */
status = luaVM_loadbytecode(L, bytecode, bc_len, "myscript");
lua_pcall(L, 0, 0, 0);  /* 执行脚本，注册全局函数 */

/* 调用脚本中定义的 Lua 函数 */
lua_getglobal(L, "add");       /* 获取函数 */
lua_pushinteger(L, 10);        /* 参数 1 */
lua_pushinteger(L, 20);        /* 参数 2 */
lua_pcall(L, 2, 1, 0);         /* 调用，2 个参数，1 个返回值 */
printf("Result: %lld\n", lua_tointeger(L, -1));
lua_pop(L, 1);
```

#### 场景 C：注册 C 函数供字节码调用

```c
/* 定义一个 C 函数 */
static int c_multiply(lua_State *L) {
    lua_Integer a = luaL_checkinteger(L, 1);
    lua_Integer b = luaL_checkinteger(L, 2);
    lua_pushinteger(L, a * b);
    return 1;  /* 返回值个数 */
}

/* 注册到全局环境 */
lua_pushcfunction(L, c_multiply);
lua_setglobal(L, "c_multiply");

/* 此后字节码中可以调用 c_multiply(3, 4) 得到 12 */
```

---

## 4. 字节码生成

独立 VM 不包含源码编译能力，需要使用完整版 Lua 或 `luac` 工具预先生成字节码：

```bash
# 方法 1：使用完整版 Lua 生成字节码文件
./lua -e "
  local f = assert(loadfile('myfile.lua'))
  local bc = string.dump(f)
  local out = assert(io.open('myfile.luac', 'wb'))
  out:write(bc)
  out:close()
"

# 方法 2：使用标准 luac 编译器
luac -o myfile.luac myfile.lua
```

生成的 `.luac` 文件包含 Lua 5.5 字节码，可直接由独立 VM 加载执行。

> **注意**：字节码格式与 Lua 版本紧密绑定，独立 VM 仅能加载与其版本匹配的字节码。

---

## 5. 项目集成建议

### 5.1 使用 CMake 子项目

在你的 CMake 项目中集成独立 VM：

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(MyApp)

# 添加 Lua VM 子目录
add_subdirectory(path/to/lua)

# 链接动态库
add_executable(myapp main.c)
target_link_libraries(myapp luavm)

# 或链接静态库（无需运行时部署 .so）
add_executable(myapp_static main.c)
target_link_libraries(myapp_static luavm_static)
```

### 5.2 使用 pkg-config（手动安装后）

```bash
# 编译
gcc -std=c99 -o myapp myapp.c $(pkg-config --cflags --libs luavm)
```

### 5.3 项目目录结构参考

```
my_project/
├── CMakeLists.txt
├── main.c              # 你的 C 程序
├── scripts/
│   ├── game_logic.lua  # Lua 源码
│   └── game_logic.luac # 预编译字节码
└── lua/                # Lua VM 源码（或已安装到系统）
    ├── lua.h
    ├── luavm.h
    └── libluavm.so
```

---

## 6. 常见问题

**Q：运行时报错 `libluavm.so: cannot open shared object file`？**

设置 `LD_LIBRARY_PATH` 指向库所在目录，或将库安装到系统路径后执行 `sudo ldconfig`。

**Q：加载 `.lua` 文本文件报错 `attempt to load a text chunk`？**

独立 VM 不支持加载源码文本，必须先将 `.lua` 编译为 `.luac` 字节码再加载。

**Q：能否同时链接 `libluavm` 和完整版 `liblua`？**

不建议。两者包含大量同名符号，会导致链接冲突。每个程序应选择其一。

**Q：静态库和动态库如何选择？**

- **动态库**（`.so`）：适合多个程序共用 VM、方便升级、减少可执行文件体积。
- **静态库**（`.a`）：适合嵌入式部署、独立分发、无需运行时配置。
