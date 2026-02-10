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
#include "lbaselib_cj_helpers.h"


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
  if (cangjie_has_tag(L, 1, "Some")) {
    lua_rawgeti(L, 1, 1);
    return 1;
  }
  return luaL_error(L, "Option is None: cannot getOrThrow");
}

/* Option.isSome() */
static int cangjie_option_isSome (lua_State *L) {
  lua_pushboolean(L, cangjie_has_tag(L, 1, "Some"));
  return 1;
}

/* Option.isNone() */
static int cangjie_option_isNone (lua_State *L) {
  lua_pushboolean(L, cangjie_has_tag(L, 1, "None"));
  return 1;
}

/* Option.getOrDefault(default) - accepts a value or a function */
static int cangjie_option_getOrDefault (lua_State *L) {
  if (cangjie_has_tag(L, 1, "Some")) {
    lua_rawgeti(L, 1, 1);
    return 1;
  }
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

typedef struct {
  const char *name;
  lua_CFunction func;
} OptionMethod;

static const OptionMethod option_methods[] = {
  {"getOrThrow", cangjie_option_getOrThrow},
  {"isSome", cangjie_option_isSome},
  {"isNone", cangjie_option_isNone},
  {"getOrDefault", cangjie_option_getOrDefault},
  {NULL, NULL}
};

/* __index handler for Option values */
static int cangjie_option_index (lua_State *L) {
  const char *key = luaL_checkstring(L, 2);
  const OptionMethod *method;
  /* Check raw access first */
  lua_pushvalue(L, 2);
  lua_rawget(L, 1);
  if (!lua_isnil(L, -1)) return 1;
  lua_pop(L, 1);
  /* Method dispatch */
  for (method = option_methods; method->name != NULL; method++) {
    if (strcmp(key, method->name) == 0) {
      lua_pushcfunction(L, method->func);
      lua_pushvalue(L, 1);
      lua_pushcclosure(L, cangjie_bound_method, 2);
      return 1;
    }
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
  if (cangjie_has_tag(L, 1, "None")) {
    lua_pushvalue(L, 2);  /* return default */
    return 1;
  }
  if (cangjie_has_tag(L, 1, "Some")) {
    lua_rawgeti(L, 1, 1);  /* unwrap Some */
    return 1;
  }
  /* Otherwise return opt as-is */
  lua_pushvalue(L, 1);
  return 1;
}

/* __cangjie_option_wrap(value) — wrap non-Option values into Some(value). */
int luaB_option_wrap (lua_State *L) {
  if (lua_isnil(L, 1)) {
    lua_getglobal(L, "None");
    return 1;
  }
  if (cangjie_has_tag(L, 1, "Some") || cangjie_has_tag(L, 1, "None")) {
    lua_pushvalue(L, 1);
    return 1;
  }
  return cangjie_some(L);
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
