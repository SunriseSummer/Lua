# Rune 类型优化：从 Metatable 到 Native Tagged Value

## 概述

本文档记录了 Rune 类型从基于 metatable 的表实现优化为 Lua 虚拟机原生 Tagged Value 类型的技术方案和实现细节。

## 优化动机

原始实现中，每个 Rune 实例是一个 Lua 表（table）：

```
旧方案: Rune = { [1] = code_point, metatable = __rune_metatable }
```

每个 Rune 值需要：
- 一个 Lua table 对象（包含 hash 表、数组部分、GC 头部等）
- metatable 引用和查找开销
- 相等/比较运算需要通过 metamethod 调用（函数调用开销）
- 字面量 `r'A'` 编译为 `Rune(65)` 函数调用，有运行时构造开销

这导致 Rune 类型内存开销大（约 100+ 字节/实例）、运算效率低（每次比较都需要 metamethod 查表和 C 函数调用）。

## 优化方案

将 Rune 作为 TValue（Tagged Value）的一种原生类型，与 nil、boolean、number 等类型平级：

```
新方案: TValue { tag = LUA_VRUNE, value.i = code_point }
```

每个 Rune 值仅需 16 字节（一个 TValue），无 GC 开销，比较运算在 VM 中直接完成。

## 实现细节

### 1. 类型系统扩展

**lua.h** — 新增类型标签：
```c
#define LUA_TRUNE    9
#define LUA_NUMTYPES 10
```

**lobject.h** — 新增 Rune 宏：
```c
#define LUA_VRUNE    makevariant(LUA_TRUNE, 0)
#define ttisrune(o)  checktag((o), LUA_VRUNE)
#define runevalue(o) check_exp(ttisrune(o), val_(o).i)
#define setrunevalue(obj,x) \
  { TValue *io=(obj); val_(io).i=(x); settt_(io, LUA_VRUNE); }
```

Rune 复用 TValue 中的整数字段 `value.i` 存储 Unicode 码点，通过不同的类型标签 `LUA_VRUNE` 与整数 `LUA_VNUMINT` 区分。

### 2. C API 扩展

**lapi.c** — 新增 API 函数：
```c
LUA_API void lua_pushrune(lua_State *L, lua_Integer cp);  // 压入 Rune 值
LUA_API lua_Integer lua_torune(lua_State *L, int idx);     // 读取 Rune 码点
```

**lua.h** — 新增便利宏：
```c
#define lua_isrune(L,n) (lua_type(L, (n)) == LUA_TRUNE)
```

### 3. 类型名称注册

**ltm.c** — 类型名称数组增加 "Rune"：
```c
const char *const luaT_typenames_[LUA_TOTALTYPES] = {
  "no value",
  "nil", "boolean", "userdata", "number",
  "string", "table", "function", "userdata", "thread",
  "Rune",          // <-- 新增
  "upvalue", "proto"
};
```

`type(r'A')` 自动返回 `"Rune"`，无需特殊判断。

### 4. 编译器支持

**lparser.h** — 新增表达式类型：
```c
VKRUNE,  // Rune 常量; ival = Unicode 码点
```

**lparser.c** — Rune 字面量直接生成常量：
```c
// 旧方案: r'A' -> 编译为 Rune(65) 函数调用
// 新方案: r'A' -> 编译为 VKRUNE 常量 (直接加载)
case TK_RUNE:
  init_exp(v, VKRUNE, 0);
  v->u.ival = ls->t.seminfo.i;
  luaX_next(ls);
  return;
```

**lcode.c** — 代码生成处理 VKRUNE：
- `luaK_runeK()`: 创建 Rune 常量（与整数常量用不同的 tag 区分）
- `luaK_rune()`: 通过 `OP_LOADK` 加载 Rune 常量到寄存器
- `discharge2reg()`, `luaK_exp2K()`, `const2exp()` 等均增加 VKRUNE 分支

### 5. VM 运算支持

**lvm.c** — 原生比较运算：
```c
// 相等比较
case LUA_VRUNE:
  return (runevalue(t1) == runevalue(t2));

// 大小比较
if (ttisrune(l) && ttisrune(r))
  return runevalue(l) < runevalue(r);  // LT
  return runevalue(l) <= runevalue(r); // LE
```

**lvm.h** — 字符串连接自动转换：
```c
#define cvt2str(o) (ttisnumber(o) || ttisrune(o))
```

Rune 在字符串拼接/插值时自动转换为 UTF-8 字符串。

### 6. 字符串转换

**lobject.c** — `luaO_tostringbuff()` 增加 Rune 分支：
```c
if (ttisrune(obj)) {
  int nbytes = cjU_utf8encode(buff, runevalue(obj));
  if (nbytes == 0) { buff[0] = '?'; return 1; }
  return cast_uint(nbytes);
}
```

**lauxlib.c** — `luaL_tolstring()` 增加 `LUA_TRUNE` case。

### 7. 运行时函数适配

**lbaselib_cj.c** — 简化 Rune 辅助函数：
```c
static int is_rune(lua_State *L, int idx) {
  return lua_type(L, idx) == LUA_TRUNE;   // 直接类型检查
}
static lua_Integer rune_getcp(lua_State *L, int idx) {
  return lua_torune(L, idx);              // 直接读取码点
}
static void push_rune(lua_State *L, lua_Integer cp) {
  lua_pushrune(L, cp);                    // 直接压入 Rune
}
```

`Rune()` 构造函数、`Int64(rune)`、`String(rune)` 等转换函数保持语义不变。
metatable 初始化函数 `luaB_rune_init()` 不再需要实际操作。

## 代码架构优化

### UTF-8 工具函数整合

优化前，UTF-8 编解码函数存在多处重复：
- `lobject.c` — inline UTF-8 编码（Rune tostring）
- `lauxlib.c` — inline UTF-8 编码（luaL_tolstring）
- `lbaselib_cj.c` — `utf8_encode()`, `utf8_decode_single()`, `utf8_char_len()`, `utf8_decode_cj()`, `utf8_charcount()`, `utf8_byte_offset()`

优化后，统一到 `lcjutf8.c` / `lcjutf8.h`：

| 文件 | 函数 | 用途 |
|------|------|------|
| `lcjutf8.c` / `lcjutf8.h` | `cjU_utf8encode()` | 码点→UTF-8 编码 |
| | `cjU_charlen()` | 判断 UTF-8 前导字节长度 |
| | `cjU_decodesingle()` | 解码单字符串为码点 |
| | `cjU_decode()` | 解码一个 UTF-8 序列 |
| | `cjU_charcount()` | 统计字符串中 UTF-8 字符数 |
| | `cjU_byteoffset()` | 字符索引→字节偏移 |

## 性能对比

| 指标 | 旧方案（metatable） | 新方案（Tagged Value） |
|------|---------------------|------------------------|
| 单个 Rune 内存 | ~120 字节（table + metatable ref） | 16 字节（TValue） |
| 创建开销 | 分配 table + 设置 metatable | 设置 tag + 写入整数 |
| 相等比较 | metamethod 查表 + C 调用 | 直接整数比较 |
| 大小比较 | metamethod 查表 + C 调用 | 直接整数比较 |
| 字面量编译 | 函数调用 `Rune(cp)` | 常量加载 `OP_LOADK` |
| GC 压力 | 每个 Rune 参与 GC | 无 GC（非引用类型） |
| type() 检查 | getmetatable + 比较 | 单次类型标签比较 |

## 文件变更清单

| 文件 | 变更说明 |
|------|----------|
| `src/include/lua.h` | 添加 `LUA_TRUNE`、`lua_pushrune`、`lua_torune`、`lua_isrune` |
| `src/include/lobject.h` | 添加 Rune 类型宏 |
| `src/include/lparser.h` | 添加 `VKRUNE` 表达式类型 |
| `src/include/lvm.h` | 更新 `cvt2str` 宏支持 Rune |
| `src/include/lcjutf8.h` | **新文件** — 共享 UTF-8 工具函数声明（含 `cjU_utf8encode`） |
| `src/core/runtime/lapi.c` | 实现 `lua_pushrune`、`lua_torune` |
| `src/core/runtime/lvm.c` | Rune 原生相等/大小比较 |
| `src/core/object/lobject.c` | `luaO_tostringbuff()` Rune 分支 |
| `src/core/object/ltm.c` | 类型名称数组添加 "Rune" |
| `src/compiler/lparser.c` | Rune 字面量编译为 VKRUNE 常量 |
| `src/compiler/lcode.c` | VKRUNE 代码生成 |
| `src/libs/lbaselib.c` | `type()` 函数简化 |
| `src/libs/lbaselib_cj.c` | Rune 辅助函数简化，消除重复代码 |
| `src/libs/lauxlib.c` | `luaL_tolstring()` 支持 Rune |
| `src/libs/lcjutf8.c` | **新文件** — 共享 UTF-8 工具函数实现 |
| `makefile` | 编译 `lcjutf8.c` |
