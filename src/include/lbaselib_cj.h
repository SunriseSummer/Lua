/*
** $Id: lbaselib_cj.h $
** Cangjie runtime support — public API header
**
** This header declares all Cangjie-specific runtime functions that are
** registered into the Lua state during library initialization.  The
** implementation is split across several compilation units:
**
**   lbaselib_cj.c         — OOP core: class/struct instantiation, method
**                           binding, inheritance, enum, tuple, overloading,
**                           array, iterator, pattern matching runtime.
**   lbaselib_cj_string.c  — String support: UTF-8 caching, indexing,
**                           slicing, built-in string methods, metatable.
**   lbaselib_cj_option.c  — Option type: Some/None, coalesce (??),
**                           getOrThrow/isSome/isNone/getOrDefault.
**
** See Copyright Notice in lua.h
*/

#ifndef lbaselib_cj_h
#define lbaselib_cj_h

#include "lua.h"
#include "llimits.h"


/*
** ============================================================
** Shared bound method helper (inline)
**
** Used by class instances, type extensions, enum values, Option,
** and string methods.  When called, it prepends the bound object
** (upvalue 2) before the caller-supplied arguments and delegates
** to the original function (upvalue 1).
**
** Upvalue layout:
**   upvalue 1 = the original function
**   upvalue 2 = the bound object (self)
** ============================================================
*/
static inline int cj_bound_method_call (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  int top_before;
  lua_pushvalue(L, lua_upvalueindex(1));  /* push function */
  lua_pushvalue(L, lua_upvalueindex(2));  /* push self */
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);                  /* push original args */
  }
  top_before = nargs;
  lua_call(L, nargs + 1, LUA_MULTRET);
  return lua_gettop(L) - top_before;      /* return only new results */
}


/* ============================================================
** Cangjie OOP runtime
** ============================================================ */
LUAI_FUNC int luaB_setup_class (lua_State *L);
LUAI_FUNC int luaB_extend_type (lua_State *L);
LUAI_FUNC int luaB_copy_to_type (lua_State *L);
LUAI_FUNC int luaB_set_parent (lua_State *L);
LUAI_FUNC int luaB_super_init (lua_State *L);
LUAI_FUNC int luaB_is_instance (lua_State *L);
LUAI_FUNC int luaB_match_tag (lua_State *L);
LUAI_FUNC int luaB_match_tuple (lua_State *L);
LUAI_FUNC int luaB_setup_enum (lua_State *L);
LUAI_FUNC int luaB_tuple (lua_State *L);
LUAI_FUNC int luaB_named_call (lua_State *L);
LUAI_FUNC int luaB_overload (lua_State *L);
LUAI_FUNC int luaB_array_init (lua_State *L);
LUAI_FUNC int luaB_option_init (lua_State *L);
LUAI_FUNC int luaB_coalesce (lua_State *L);
LUAI_FUNC int luaB_array_slice (lua_State *L);
LUAI_FUNC int luaB_array_slice_set (lua_State *L);
LUAI_FUNC int luaB_iter (lua_State *L);
LUAI_FUNC int luaB_apply_interface (lua_State *L);

/* ============================================================
** Cangjie string support
** ============================================================ */
LUAI_FUNC int luaB_str_index (lua_State *L);
LUAI_FUNC int luaB_str_newindex (lua_State *L);
LUAI_FUNC int luaB_str_slice (lua_State *L);
LUAI_FUNC int luaB_setup_string_meta (lua_State *L);
LUAI_FUNC int luaB_byte_array_from_string (lua_State *L);
LUAI_FUNC int luaB_string_from_byte_array (lua_State *L);

/* ============================================================
** Cangjie type conversion functions
** ============================================================ */
LUAI_FUNC int luaB_cangjie_int64 (lua_State *L);
LUAI_FUNC int luaB_cangjie_float64 (lua_State *L);
LUAI_FUNC int luaB_cangjie_string (lua_State *L);
LUAI_FUNC int luaB_cangjie_bool (lua_State *L);
LUAI_FUNC int luaB_cangjie_rune (lua_State *L);

#endif
