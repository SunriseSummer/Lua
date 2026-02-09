/*
** Shared helpers for Cangjie base libraries.
** Extracted to avoid duplication across runtime modules.
** See Copyright Notice in lua.h
*/

#ifndef lbaselib_cj_helpers_h
#define lbaselib_cj_helpers_h

#include "lua.h"

/*
** Upvalue-based bound method: when called, prepend the bound object.
** upvalue 1 = the original function, upvalue 2 = the bound object.
*/
static inline int cangjie_bound_method (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  int top_before;
  lua_pushvalue(L, lua_upvalueindex(1));  /* push function */
  lua_pushvalue(L, lua_upvalueindex(2));  /* push self */
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);  /* push original args */
  }
  top_before = nargs;  /* original args count */
  lua_call(L, nargs + 1, LUA_MULTRET);
  return lua_gettop(L) - top_before;  /* return new results only */
}

#endif
