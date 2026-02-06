# Cangjie 语法前端改造方案

## 目标
在复用 Lua 虚拟机与字节码执行模型的前提下，为解释器新增仓颉（Cangjie）基础语法支持，覆盖控制流、基础数据类型、集合类型与函数等核心能力，并保留 Lua VM 运行时行为。

## 总体思路
1. **前端翻译层**：在加载脚本时增加轻量级源码转换，将仓颉语法转换为等价的 Lua 源码，再交由现有 Lua 解析器与编译器处理。
2. **最小侵入**：仅修改 `lauxlib.c` 的加载流程，保持 VM/编译器实现不变，确保兼容现有字节码执行逻辑。
3. **渐进支持**：本次仅覆盖基础语法，未来可在翻译层持续扩展语法映射。

## 语法映射（基础）
- **变量声明**：`let` / `var` → `local`
- **函数**：`func name(params): Type { ... }` → `function name(params) ... end`
- **控制流**：
  - `if (cond) { ... }` → `if (cond) then ... end`
  - `else if` → `elseif`
  - `while (cond) { ... }` → `while (cond) do ... end`
  - `for (i in 1..=n) { ... }` → `for i = 1, n do ... end`
  - `for (item in list) { ... }` → `for _, item in ipairs(list) do ... end`
- **集合类型**：`[1, 2, 3]` → `{1, 2, 3}`（Lua 表）
- **基础字面量**：`null` → `nil`
- **逻辑与比较**：`&&`/`||`/`!`/`!=` → `and`/`or`/`not`/`~=`
- **注释**：`//`、`/* */` → Lua 注释

## 实现位置
- **`lauxlib.c`**：
  - 在 `luaL_loadbufferx` 中增加 `cj_translate` 转换逻辑。
  - `luaL_loadfilex` 读取文本文件时先加载为字符串，再复用上述转换。

## 测试策略
- 新增 `testes/cangjie_basic.lua`：覆盖函数、控制流、集合、逻辑运算、空值等基础语法。
- `testes/all.lua` 仅运行 Cangjie 新测试，避免 Lua 语法测试干扰。

## 未来扩展方向
- 补充类型系统、结构体/类、泛型、模块系统等更高级语法。
- 对迭代器与集合类型增加更完善的语义映射。
- 更精细的错误定位与语法提示。
