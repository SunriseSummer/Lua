/*
** ArrayStack implementation for Cangjie collections.
*/

#define lcollection_arraystack_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"

static int arraystack_iter_index (lua_State *L);
static int arraystack_iter_next (lua_State *L);
static int arraystack_to_string (lua_State *L);

static void push_none (lua_State *L) {
  lua_getglobal(L, "None");
}

static void push_option (lua_State *L, int idx) {
  int abs = lua_absindex(L, idx);
  if (lua_isnil(L, abs)) {
    push_none(L);
    return;
  }
  lua_newtable(L);
  lua_pushliteral(L, "Some");
  lua_setfield(L, -2, "__tag");
  lua_pushvalue(L, abs);
  lua_rawseti(L, -2, 1);
  lua_getglobal(L, "__option_mt");
  if (!lua_isnil(L, -1))
    lua_setmetatable(L, -2);
  else
    lua_pop(L, 1);
}

static void arraystack_set_size (lua_State *L, int obj, lua_Integer size) {
  lua_pushinteger(L, size);
  lua_setfield(L, obj, "size");
  lua_pushinteger(L, size);
  lua_setfield(L, obj, "__n");
  lua_getfield(L, obj, "__data");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  lua_pop(L, 1);
}

static lua_Integer arraystack_get_size (lua_State *L, int obj) {
  lua_Integer size;
  lua_getfield(L, obj, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return size;
}

static void arraystack_set_capacity (lua_State *L, int obj, lua_Integer cap) {
  lua_pushinteger(L, cap);
  lua_setfield(L, obj, "capacity");
}

static lua_Integer arraystack_get_capacity (lua_State *L, int obj) {
  lua_Integer cap;
  lua_getfield(L, obj, "capacity");
  cap = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return cap;
}

static void arraystack_reserve (lua_State *L, int obj, lua_Integer additional) {
  lua_Integer size = arraystack_get_size(L, obj);
  lua_Integer cap = arraystack_get_capacity(L, obj);
  if (additional <= 0) return;
  if (cap - size >= additional) return;
  arraystack_set_capacity(L, obj, size + additional);
}

static int arraystack_index (lua_State *L) {
  if (lua_type(L, 2) == LUA_TNUMBER) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer size = arraystack_get_size(L, 1);
    if (idx < 0 || idx >= size)
      return luaL_error(L, "ArrayStack index out of bounds");
    lua_getfield(L, 1, "__data");
    lua_geti(L, -1, idx);
    return 1;
  }
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0 || strcmp(key, "capacity") == 0) {
      lua_getfield(L, 1, key);
      return 1;
    }
  }
  lua_pushvalue(L, 2);
  lua_rawget(L, lua_upvalueindex(1));
  if (lua_isfunction(L, -1)) {
    lua_pushvalue(L, -1);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  return 1;
}

static int arraystack_newindex (lua_State *L) {
  if (lua_type(L, 2) == LUA_TNUMBER) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer size = arraystack_get_size(L, 1);
    if (idx < 0 || idx >= size)
      return luaL_error(L, "ArrayStack index out of bounds");
    lua_getfield(L, 1, "__data");
    lua_pushvalue(L, 3);
    lua_seti(L, -2, idx);
    lua_pop(L, 1);
    return 0;
  }
  lua_rawset(L, 1);
  return 0;
}

static int arraystack_new (lua_State *L) {
  int argc = lua_gettop(L) - 1;
  lua_Integer capacity = 8;
  int obj;
  lua_newtable(L);
  obj = lua_gettop(L);
  lua_pushvalue(L, 1);
  lua_setfield(L, obj, "__class");
  lua_newtable(L);
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_pushcclosure(L, arraystack_index, 1);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, arraystack_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_pushcfunction(L, arraystack_to_string);
  lua_setfield(L, -2, "__tostring");
  lua_setmetatable(L, obj);
  lua_newtable(L);
  lua_setfield(L, obj, "__data");
  if (argc == 1 && lua_isinteger(L, 2)) {
    capacity = lua_tointeger(L, 2);
    luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
    if (capacity < 8) capacity = 8;
  }
  arraystack_set_capacity(L, obj, capacity);
  arraystack_set_size(L, obj, 0);
  return 1;
}

static int arraystack_add (lua_State *L) {
  lua_Integer size = arraystack_get_size(L, 1);
  lua_Integer cap = arraystack_get_capacity(L, 1);
  if (size + 1 > cap) arraystack_reserve(L, 1, 1);
  lua_getfield(L, 1, "__data");
  lua_pushvalue(L, 2);
  lua_seti(L, -2, size);
  lua_pop(L, 1);
  arraystack_set_size(L, 1, size + 1);
  return 0;
}

static int arraystack_clear (lua_State *L) {
  lua_newtable(L);
  lua_setfield(L, 1, "__data");
  arraystack_set_size(L, 1, 0);
  return 0;
}

static int arraystack_is_empty (lua_State *L) {
  lua_pushboolean(L, arraystack_get_size(L, 1) == 0);
  return 1;
}

static int arraystack_iter_index (lua_State *L) {
  lua_pushvalue(L, 2);
  lua_rawget(L, lua_upvalueindex(1));
  if (lua_isfunction(L, -1)) {
    lua_pushvalue(L, -1);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  return 1;
}

static int arraystack_iter_next (lua_State *L) {
  lua_Integer idx;
  lua_Integer size;
  lua_getfield(L, 1, "__idx");
  idx = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : -1;
  lua_pop(L, 1);
  idx++;
  lua_getfield(L, 1, "__data");
  lua_getfield(L, -1, "__n");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (idx >= size) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  lua_geti(L, -1, size - 1 - idx);
  lua_pushinteger(L, idx);
  lua_setfield(L, 1, "__idx");
  push_option(L, -1);
  return 1;
}

static int arraystack_peek (lua_State *L) {
  lua_Integer size = arraystack_get_size(L, 1);
  if (size <= 0) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, 1, "__data");
  lua_geti(L, -1, size - 1);
  push_option(L, -1);
  return 1;
}

static int arraystack_remove (lua_State *L) {
  lua_Integer size = arraystack_get_size(L, 1);
  int data_idx;
  if (size <= 0) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, 1, "__data");
  data_idx = lua_gettop(L);
  lua_geti(L, data_idx, size - 1);
  push_option(L, -1);
  lua_replace(L, -2);
  lua_pushnil(L);
  lua_seti(L, data_idx, size - 1);
  lua_pop(L, 1);
  arraystack_set_size(L, 1, size - 1);
  return 1;
}

static int arraystack_reserve_method (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  arraystack_reserve(L, 1, additional);
  return 0;
}

static int arraystack_to_array (lua_State *L) {
  lua_Integer size = arraystack_get_size(L, 1);
  lua_newtable(L);
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, size - 1 - i);
    lua_seti(L, -3, i);
  }
  lua_pop(L, 1);
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int arraystack_iterator (lua_State *L) {
  lua_newtable(L);
  lua_getfield(L, 1, "__data");
  lua_setfield(L, -2, "__data");
  lua_pushinteger(L, -1);
  lua_setfield(L, -2, "__idx");
  lua_newtable(L);
  lua_pushcfunction(L, arraystack_iter_next);
  lua_setfield(L, -2, "next");
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, arraystack_iter_index, 1);
  lua_setfield(L, -2, "__index");
  lua_setmetatable(L, -3);
  lua_pop(L, 1);
  return 1;
}

static int arraystack_to_string (lua_State *L) {
  lua_Integer size = arraystack_get_size(L, 1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    size_t len;
    const char *s;
    if (i > 0) luaL_addstring(&b, ", ");
    lua_geti(L, -1, size - 1 - i);
    s = luaL_tolstring(L, -1, &len);
    luaL_addlstring(&b, s, len);
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  return 1;
}

static const luaL_Reg arraystack_methods[] = {
  {"add", arraystack_add},
  {"clear", arraystack_clear},
  {"isEmpty", arraystack_is_empty},
  {"iterator", arraystack_iterator},
  {"peek", arraystack_peek},
  {"remove", arraystack_remove},
  {"reserve", arraystack_reserve_method},
  {"toArray", arraystack_to_array},
  {"toString", arraystack_to_string},
  {NULL, NULL}
};

int luaB_arraystack_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, arraystack_methods, 0);
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, arraystack_new, 1);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, -2);
  lua_setglobal(L, "ArrayStack");
  return 0;
}
