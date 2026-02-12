/*
** Cangjie Range type support - Range struct and range literals.
**
** Implements a Range class with fields start/end/step/hasEnd/isClosed,
** plus iterator() and toString() helpers. Range instances can be created
** via Range(...) or range literals (0..10:2), which call __cangjie_range.
*/

#define lbaselib_cj_range_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"


static void push_none (lua_State *L) {
  lua_getglobal(L, "None");
}


static void push_some (lua_State *L, int idx) {
  idx = lua_absindex(L, idx);
  lua_getglobal(L, "Some");
  lua_pushvalue(L, idx);
  lua_call(L, 1, 1);
}


static lua_Integer get_int_field (lua_State *L, int idx, const char *name,
                                  lua_Integer def) {
  lua_Integer val;
  idx = lua_absindex(L, idx);
  lua_getfield(L, idx, name);
  if (lua_isinteger(L, -1))
    val = lua_tointeger(L, -1);
  else
    val = def;
  lua_pop(L, 1);
  return val;
}


static int range_init (lua_State *L) {
  int nargs = lua_gettop(L) - 1;
  lua_Integer start = luaL_checkinteger(L, 2);
  lua_Integer end = luaL_checkinteger(L, 3);
  lua_Integer step = 1;
  int is_closed = 0;
  int has_end = 1;
  if (nargs >= 3 && !lua_isnil(L, 4))
    step = luaL_checkinteger(L, 4);
  if (nargs >= 4 && !lua_isnil(L, 5))
    is_closed = lua_toboolean(L, 5);
  if (nargs >= 5 && !lua_isnil(L, 6))
    has_end = lua_toboolean(L, 6);
  luaL_argcheck(L, step != 0, 4, "range step must not be 0");
  lua_pushinteger(L, start);
  lua_setfield(L, 1, "start");
  lua_pushinteger(L, end);
  lua_setfield(L, 1, "end");
  lua_pushinteger(L, step);
  lua_setfield(L, 1, "step");
  lua_pushinteger(L, 1);
  lua_setfield(L, 1, "hasStart");
  lua_pushinteger(L, has_end ? 1 : 0);
  lua_setfield(L, 1, "hasEnd");
  lua_pushinteger(L, is_closed ? 1 : 0);
  lua_setfield(L, 1, "isClosed");
  lua_pushliteral(L, "Range");
  lua_setfield(L, 1, "__tag");
  return 0;
}


static int range_iterator_next (lua_State *L) {
  int range_idx = lua_upvalueindex(1);
  lua_Integer current = lua_tointeger(L, lua_upvalueindex(2));
  lua_Integer end = get_int_field(L, range_idx, "end", 0);
  lua_Integer step = get_int_field(L, range_idx, "step", 1);
  int has_end = get_int_field(L, range_idx, "hasEnd", 1) != 0;
  int is_closed = get_int_field(L, range_idx, "isClosed", 0) != 0;
  lua_Integer next = current + step;
  if (has_end) {
    if (step > 0) {
      if (is_closed ? (next > end) : (next >= end)) {
        push_none(L);
        return 1;
      }
    }
    else {
      if (is_closed ? (next < end) : (next <= end)) {
        push_none(L);
        return 1;
      }
    }
  }
  lua_pushinteger(L, next);
  lua_replace(L, lua_upvalueindex(2));
  lua_pushinteger(L, next);
  push_some(L, -1);
  return 1;
}


static int range_iterator (lua_State *L) {
  lua_Integer start = get_int_field(L, 1, "start", 0);
  lua_Integer step = get_int_field(L, 1, "step", 1);
  lua_pushvalue(L, 1);
  lua_pushinteger(L, start - step);
  lua_pushcclosure(L, range_iterator_next, 2);
  return 1;
}


static int range_tostring (lua_State *L) {
  lua_Integer start = get_int_field(L, 1, "start", 0);
  lua_Integer end = get_int_field(L, 1, "end", 0);
  lua_Integer step = get_int_field(L, 1, "step", 1);
  int has_end = get_int_field(L, 1, "hasEnd", 1) != 0;
  int is_closed = get_int_field(L, 1, "isClosed", 0) != 0;
  if (!has_end) {
    lua_pushfstring(L, "%d..", (int)start);
    return 1;
  }
  if (step == 1) {
    lua_pushfstring(L, is_closed ? "%d..=%d" : "%d..%d",
                    (int)start, (int)end);
    return 1;
  }
  lua_pushfstring(L, is_closed ? "%d..=%d:%d" : "%d..%d:%d",
                  (int)start, (int)end, (int)step);
  return 1;
}


static const luaL_Reg range_methods[] = {
  {"init", range_init},
  {"iterator", range_iterator},
  {"toString", range_tostring},
  {"__tostring", range_tostring},
  {NULL, NULL}
};


int luaB_range_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, range_methods, 0);
  cangjie_register_class_global(L, "Range");
  return 0;
}


/*
** __cangjie_range(start, end, step, inclusive)
** Build a Range instance for range literals.
*/
int luaB_range (lua_State *L) {
  luaL_checkinteger(L, 1);
  luaL_checkinteger(L, 2);
  luaL_checkinteger(L, 3);
  lua_getglobal(L, "Range");
  lua_pushvalue(L, 1);
  lua_pushvalue(L, 2);
  lua_pushvalue(L, 3);
  lua_pushvalue(L, 4);
  lua_pushinteger(L, 1);
  lua_call(L, 5, 1);
  return 1;
}
