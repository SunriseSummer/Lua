/*
** Shared helpers for Cangjie base libraries.
** Extracted to avoid duplication across runtime modules.
** See Copyright Notice in lua.h
*/

#ifndef lbaselib_cj_helpers_h
#define lbaselib_cj_helpers_h

#include <string.h>

#include "lua.h"
#include "lbaselib_cj.h"

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

/*
** Check whether a table carries a specific __tag.
*/
static inline int cangjie_has_tag (lua_State *L, int idx, const char *tag) {
  int result = 0;
  if (lua_istable(L, idx)) {
    lua_getfield(L, idx, "__tag");
    if (lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), tag) == 0) {
      result = 1;
    }
    lua_pop(L, 1);
  }
  return result;
}


/*
** Register a class table as a global with __call constructor support.
** Expects the class table to be on the top of the stack. Any existing
** stack values below it are preserved and restored.
*/
static inline void cangjie_register_class_global (lua_State *L,
                                                  const char *name) {
  int top = lua_gettop(L);
  /* Move class table to stack index 1 for luaB_setup_class. */
  lua_insert(L, 1);
  luaB_setup_class(L);
  /* Reuse the class table at index 1 to set the global name. */
  lua_pushvalue(L, 1);
  lua_setglobal(L, name);
  /* Remove the temporary class table and restore original stack size. */
  lua_remove(L, 1);
  lua_settop(L, top);
}

#endif
