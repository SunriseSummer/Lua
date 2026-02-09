/*
** $Id: lbaselib_cj_option.c $
** Cangjie Option type support - Some/None, coalesce (??) operator,
** and Option metatable with getOrThrow/isSome/isNone/getOrDefault.
** Split from lbaselib_cj.c
**
** Contents:
**   cangjie_some               — Some(value) constructor
**   cangjie_option_getOrThrow  — Unwrap Some or error on None
**   cangjie_option_isSome      — Check if Option is Some
**   cangjie_option_isNone      — Check if Option is None
**   cangjie_option_getOrDefault — Unwrap Some or return default
**   cangjie_option_index       — __index handler for Option values
**   luaB_coalesce              — ?? operator runtime implementation
**   luaB_option_init           — Register Some/None globals at init
**
** See Copyright Notice in lua.h
*/

#define lbaselib_cj_option_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "lbaselib_cj.h"


/* option_bound_method — Delegates to the shared cj_bound_method_call()
** helper defined in lbaselib_cj.h (eliminates duplicate implementation). */
static int option_bound_method (lua_State *L) {
  return cj_bound_method_call(L);
}


/*
** ============================================================
** Option constructors and methods
** ============================================================
*/

/* Some(value) constructor - creates {__tag="Some", [1]=value} with metatable */
static int cangjie_some (lua_State *L) {
  lua_newtable(L);
  lua_pushliteral(L, "Some");
  lua_setfield(L, -2, "__tag");
  lua_pushvalue(L, 1);
  lua_rawseti(L, -2, 1);
  /* Set Option metatable */
  lua_getglobal(L, "__option_mt");
  if (!lua_isnil(L, -1))
    lua_setmetatable(L, -2);
  else
    lua_pop(L, 1);
  return 1;
}

/* Option.getOrThrow() - unwrap Some value or error on None */
static int cangjie_option_getOrThrow (lua_State *L) {
  lua_getfield(L, 1, "__tag");
  if (lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0) {
    lua_pop(L, 1);
    lua_rawgeti(L, 1, 1);
    return 1;
  }
  return luaL_error(L, "Option is None: cannot getOrThrow");
}

/* Option.isSome() */
static int cangjie_option_isSome (lua_State *L) {
  int result;
  lua_getfield(L, 1, "__tag");
  result = lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0;
  lua_pop(L, 1);
  lua_pushboolean(L, result);
  return 1;
}

/* Option.isNone() */
static int cangjie_option_isNone (lua_State *L) {
  int result;
  lua_getfield(L, 1, "__tag");
  result = lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "None") == 0;
  lua_pop(L, 1);
  lua_pushboolean(L, result);
  return 1;
}

/* Option.getOrDefault(default) - accepts a value or a function */
static int cangjie_option_getOrDefault (lua_State *L) {
  lua_getfield(L, 1, "__tag");
  if (lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0) {
    lua_pop(L, 1);
    lua_rawgeti(L, 1, 1);
    return 1;
  }
  lua_pop(L, 1);
  /* Return the default value (call it if it's a function, otherwise return directly) */
  lua_pushvalue(L, 2);
  if (lua_isfunction(L, -1)) {
    lua_call(L, 0, 1);
  }
  return 1;
}

/*
** ============================================================
** Option __index and coalesce operator
** ============================================================
*/

/* __index handler for Option values */
static int cangjie_option_index (lua_State *L) {
  const char *key = luaL_checkstring(L, 2);
  /* Check raw access first */
  lua_pushvalue(L, 2);
  lua_rawget(L, 1);
  if (!lua_isnil(L, -1)) return 1;
  lua_pop(L, 1);
  /* Method dispatch */
  if (strcmp(key, "getOrThrow") == 0) {
    lua_pushcfunction(L, cangjie_option_getOrThrow);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, option_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "isSome") == 0) {
    lua_pushcfunction(L, cangjie_option_isSome);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, option_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "isNone") == 0) {
    lua_pushcfunction(L, cangjie_option_isNone);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, option_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "getOrDefault") == 0) {
    lua_pushcfunction(L, cangjie_option_getOrDefault);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, option_bound_method, 2);
    return 1;
  }
  lua_pushnil(L);
  return 1;
}

/* __cangjie_coalesce(opt, default) — runtime for the ?? operator.
** Returns: opt if non-nil and not None; unwraps Some; else default. */
int luaB_coalesce (lua_State *L) {
  /* If opt is nil, return default */
  if (lua_isnil(L, 1)) {
    lua_pushvalue(L, 2);
    return 1;
  }
  /* If opt is a table with __tag */
  if (lua_istable(L, 1)) {
    lua_getfield(L, 1, "__tag");
    if (lua_isstring(L, -1)) {
      const char *tag = lua_tostring(L, -1);
      if (strcmp(tag, "None") == 0) {
        lua_pop(L, 1);
        lua_pushvalue(L, 2);  /* return default */
        return 1;
      }
      if (strcmp(tag, "Some") == 0) {
        lua_pop(L, 1);
        lua_rawgeti(L, 1, 1);  /* unwrap Some */
        return 1;
      }
    }
    lua_pop(L, 1);
  }
  /* Otherwise return opt as-is */
  lua_pushvalue(L, 1);
  return 1;
}

/*
** ============================================================
** Option initialization
** ============================================================
*/

/*
** luaB_option_init(L) - Register built-in Some/None globals with metatables.
** Called during library initialization.
*/
int luaB_option_init (lua_State *L) {
  /* Create Option metatable */
  lua_newtable(L);  /* mt */
  lua_pushcfunction(L, cangjie_option_index);
  lua_setfield(L, -2, "__index");
  /* Store as global __option_mt */
  lua_pushvalue(L, -1);
  lua_setglobal(L, "__option_mt");

  /* Create Some function */
  lua_pushcfunction(L, cangjie_some);
  lua_setglobal(L, "Some");

  /* Create None value: {__tag="None"} with metatable */
  lua_newtable(L);
  lua_pushliteral(L, "None");
  lua_setfield(L, -2, "__tag");
  lua_pushvalue(L, -2);  /* push mt */
  lua_setmetatable(L, -2);
  lua_setglobal(L, "None");

  lua_pop(L, 1);  /* pop mt */
  return 0;
}
