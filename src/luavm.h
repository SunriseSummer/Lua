/*
** luavm.h
** Lua Virtual Machine - Standalone Public C API
**
** This header provides the public interface for using the Lua VM
** independently of the Lua frontend (lexer/parser/compiler).
** The standalone VM can load and execute precompiled Lua bytecode.
**
** See Copyright Notice in lua.h
*/

#ifndef luavm_h
#define luavm_h

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


/*
** =======================================================================
** Standalone VM API
**
** The standalone VM library (libluavm) provides all standard Lua C API
** functions for state management, stack operations, table access, function
** calls, coroutines, GC control, and the standard libraries.
**
** The only difference from the full Lua library is that the standalone VM
** cannot load source text directly. It can only load precompiled bytecode
** (binary chunks). Attempting to load text chunks will result in a
** LUA_ERRSYNTAX error with the message:
**   "attempt to load a text chunk (no parser available)"
**
** Typical usage:
**
**   lua_State *L = luaL_newstate();
**   luaL_openlibs(L);
**   luaL_loadbufferx(L, bytecode, size, "chunk", "b");
**   lua_pcall(L, 0, LUA_MULTRET, 0);
**   lua_close(L);
**
** =======================================================================
*/


/*
** Load a precompiled bytecode buffer into the VM.
** This is a convenience wrapper around luaL_loadbufferx with mode="b".
** Returns LUA_OK on success, or an error code.
*/
#define luaVM_loadbytecode(L, buf, sz, name) \
    luaL_loadbufferx((L), (buf), (sz), (name), "b")


/*
** Check whether the VM has a text parser available.
** Returns 0 for a standalone VM build (LUA_VM_ONLY).
** Returns 1 for a full Lua build with the frontend.
*/
static int luaVM_hasparser (lua_State *L) {
  (void)L;
#ifdef LUA_VM_ONLY
  return 0;
#else
  return 1;
#endif
}


/*
** Bytecode signature byte (first byte of any valid Lua bytecode chunk).
** Can be used to validate bytecode before loading.
*/
#define LUAVM_SIGNATURE  LUA_SIGNATURE


#endif
