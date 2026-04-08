/*
** ArrayList implementation for Cangjie collections.
*/

#define lcollection_arraylist_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"

static int arraylist_eq (lua_State *L);
static int arraylist_to_string (lua_State *L);
static int arraylist_iter_index (lua_State *L);
static int arraylist_iter_next (lua_State *L);
static int arraylist_remove_range (lua_State *L);


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

static void arraylist_update_first_last (lua_State *L, int obj, lua_Integer size) {
  int abs = lua_absindex(L, obj);
  if (size <= 0) {
    push_none(L);
    lua_setfield(L, abs, "first");
    push_none(L);
    lua_setfield(L, abs, "last");
    return;
  }
  lua_getfield(L, abs, "__data");
  lua_geti(L, -1, 0);
  push_option(L, -1);
  lua_setfield(L, abs, "first");
  lua_pop(L, 1);
  lua_geti(L, -1, size - 1);
  push_option(L, -1);
  lua_setfield(L, abs, "last");
  lua_pop(L, 2);  /* pop value and __data */
}

static void arraylist_set_size (lua_State *L, int obj, lua_Integer size) {
  int abs = lua_absindex(L, obj);
  lua_pushinteger(L, size);
  lua_setfield(L, abs, "size");
  lua_pushinteger(L, size);
  lua_setfield(L, abs, "__n");
  lua_getfield(L, abs, "__data");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  lua_pop(L, 1);
  arraylist_update_first_last(L, abs, size);
}

static lua_Integer arraylist_get_size (lua_State *L, int obj) {
  lua_Integer size;
  lua_getfield(L, obj, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return size;
}

static void arraylist_set_capacity (lua_State *L, int obj, lua_Integer cap) {
  lua_pushinteger(L, cap);
  lua_setfield(L, obj, "capacity");
}

static lua_Integer arraylist_get_capacity (lua_State *L, int obj) {
  lua_Integer cap;
  lua_getfield(L, obj, "capacity");
  cap = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return cap;
}

static int arraylist_is_collection (lua_State *L, int idx) {
  if (!lua_istable(L, idx)) return 0;
  lua_getfield(L, idx, "__n");
  if (lua_isinteger(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_pop(L, 1);
  lua_getfield(L, idx, "size");
  if (lua_isinteger(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_pop(L, 1);
  return 0;
}

static int arraylist_get_collection_data (lua_State *L, int idx, lua_Integer *size, int *needs_pop) {
  int abs = lua_absindex(L, idx);
  lua_getfield(L, abs, "__data");
  if (lua_istable(L, -1)) {
    *needs_pop = 1;
    idx = lua_gettop(L);
  }
  else {
    lua_pop(L, 1);
    *needs_pop = 0;
    idx = abs;
  }
  lua_getfield(L, idx, "__n");
  if (lua_isinteger(L, -1)) {
    *size = lua_tointeger(L, -1);
    lua_pop(L, 1);
    return idx;
  }
  lua_pop(L, 1);
  lua_getfield(L, abs, "size");
  if (lua_isinteger(L, -1)) {
    *size = lua_tointeger(L, -1);
    lua_pop(L, 1);
    return idx;
  }
  lua_pop(L, 1);
  *size = 0;
  return idx;
}

static void arraylist_reserve (lua_State *L, int obj, lua_Integer additional) {
  lua_Integer size = arraylist_get_size(L, obj);
  lua_Integer cap = arraylist_get_capacity(L, obj);
  if (additional <= 0) return;
  if (cap - size >= additional) return;
  {
    lua_Integer target = size + additional;
    lua_Integer grow = (lua_Integer)(cap + cap / 2);
    lua_Integer next = grow > target ? grow : target;
    arraylist_set_capacity(L, obj, next);
  }
}

static int arraylist_append_value (lua_State *L, int obj, int value_idx) {
  int data_idx;
  lua_Integer size = arraylist_get_size(L, obj);
  lua_Integer cap = arraylist_get_capacity(L, obj);
  data_idx = lua_absindex(L, obj);
  if (size + 1 > cap) {
    arraylist_reserve(L, obj, 1);
  }
  lua_getfield(L, data_idx, "__data");
  lua_pushvalue(L, value_idx);
  lua_seti(L, -2, size);
  lua_pop(L, 1);
  arraylist_set_size(L, obj, size + 1);
  return 0;
}

static int arraylist_insert_range (lua_State *L, int obj, lua_Integer at, lua_Integer count) {
  lua_Integer size = arraylist_get_size(L, obj);
  lua_Integer cap = arraylist_get_capacity(L, obj);
  lua_Integer i;
  if (at < 0 || at > size)
    return luaL_error(L, "ArrayList index out of bounds");
  if (count <= 0) return 0;
  if (size + count > cap)
    arraylist_reserve(L, obj, count);
  lua_getfield(L, obj, "__data");
  for (i = size - 1; i >= at; i--) {
    lua_geti(L, -1, i);
    lua_seti(L, -2, i + count);
    if (i == 0) break;
  }
  lua_pop(L, 1);
  arraylist_set_size(L, obj, size + count);
  return 0;
}

static int arraylist_index (lua_State *L) {
  int obj = 1;
  if (lua_type(L, 2) == LUA_TINT64 || lua_type(L, 2) == LUA_TNUMBER) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer size = arraylist_get_size(L, obj);
    if (idx < 0 || idx >= size)
      return luaL_error(L, "ArrayList index out of bounds");
    lua_getfield(L, obj, "__data");
    lua_geti(L, -1, idx);
    return 1;
  }
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0 || strcmp(key, "capacity") == 0 ||
        strcmp(key, "first") == 0 || strcmp(key, "last") == 0) {
      lua_getfield(L, obj, key);
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

static int arraylist_newindex (lua_State *L) {
  if (lua_type(L, 2) == LUA_TINT64 || lua_type(L, 2) == LUA_TNUMBER) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer size = arraylist_get_size(L, 1);
    if (idx < 0 || idx >= size)
      return luaL_error(L, "ArrayList index out of bounds");
    lua_getfield(L, 1, "__data");
    lua_pushvalue(L, 3);
    lua_seti(L, -2, idx);
    lua_pop(L, 1);
    arraylist_update_first_last(L, 1, size);
    return 0;
  }
  lua_rawset(L, 1);
  return 0;
}

static int arraylist_new (lua_State *L) {
  int argc = lua_gettop(L) - 1;
  lua_Integer size = 0;
  lua_Integer capacity = 16;
  int obj;
  lua_newtable(L);
  obj = lua_gettop(L);
  lua_pushvalue(L, 1);
  lua_setfield(L, obj, "__class");
  lua_newtable(L);
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_pushcclosure(L, arraylist_index, 1);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, arraylist_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_pushcfunction(L, arraylist_eq);
  lua_setfield(L, -2, "__eq");
  lua_pushcfunction(L, arraylist_to_string);
  lua_setfield(L, -2, "__tostring");
  lua_setmetatable(L, obj);
  lua_newtable(L);
  lua_setfield(L, obj, "__data");
  if (argc == 0) {
    capacity = 16;
  }
  else if (argc == 1) {
    if (lua_isinteger(L, 2)) {
      capacity = lua_tointeger(L, 2);
      luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
    }
    else if (arraylist_is_collection(L, 2)) {
      lua_Integer count;
      int needs_pop;
      int data_idx = arraylist_get_collection_data(L, 2, &count, &needs_pop);
      capacity = count;
      lua_getfield(L, obj, "__data");
      for (size = 0; size < count; size++) {
        lua_geti(L, data_idx, size);
        lua_seti(L, -2, size);
      }
      lua_pop(L, 1);
      if (needs_pop) lua_pop(L, 1);
      arraylist_set_capacity(L, obj, capacity);
      arraylist_set_size(L, obj, count);
      return 1;
    }
  }
  else if (argc >= 2) {
    if (lua_isinteger(L, 2)) {
      size = lua_tointeger(L, 2);
      luaL_argcheck(L, size >= 0, 2, "size must be non-negative");
      capacity = size;
      lua_getfield(L, obj, "__data");
      for (lua_Integer i = 0; i < size; i++) {
        if (lua_isfunction(L, 3)) {
          lua_pushvalue(L, 3);
          lua_pushinteger(L, i);
          lua_call(L, 1, 1);
        }
        else {
          lua_pushvalue(L, 3);
        }
        lua_seti(L, -2, i);
      }
      lua_pop(L, 1);
    }
  }
  arraylist_set_capacity(L, obj, capacity);
  arraylist_set_size(L, obj, size);
  return 1;
}

static int arraylist_of (lua_State *L) {
  int argc = lua_gettop(L);
  int argidx = 1;
  lua_Integer count;
  int needs_pop;
  int data_idx;
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  if (argc == 1 && arraylist_is_collection(L, 1)) {
    data_idx = arraylist_get_collection_data(L, 1, &count, &needs_pop);
    lua_getfield(L, -1, "__data");
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      lua_seti(L, -2, i);
    }
    lua_pop(L, 1);
    if (needs_pop) lua_pop(L, 1);
    arraylist_set_capacity(L, -1, count);
    arraylist_set_size(L, -1, count);
    return 1;
  }
  count = argc;
  lua_getfield(L, -1, "__data");
  for (lua_Integer i = 0; i < count; i++) {
    lua_pushvalue(L, argidx + (int)i);
    lua_seti(L, -2, i);
  }
  lua_pop(L, 1);
  arraylist_set_capacity(L, -1, count);
  arraylist_set_size(L, -1, count);
  return 1;
}

static int arraylist_add (lua_State *L) {
  int obj = 1;
  int nargs = lua_gettop(L) - 1;
  if (nargs == 1) {
    if (arraylist_is_collection(L, 2)) {
      lua_Integer count;
      int needs_pop;
      int data_idx = arraylist_get_collection_data(L, 2, &count, &needs_pop);
      lua_Integer size = arraylist_get_size(L, obj);
      arraylist_insert_range(L, obj, size, count);
      lua_getfield(L, obj, "__data");
      for (lua_Integer i = 0; i < count; i++) {
        lua_geti(L, data_idx, i);
        lua_seti(L, -2, size + i);
      }
      lua_pop(L, 1);
      arraylist_update_first_last(L, obj, arraylist_get_size(L, obj));
      if (needs_pop) lua_pop(L, 1);
      return 0;
    }
    return arraylist_append_value(L, obj, 2);
  }
  if (nargs == 2) {
    if (arraylist_is_collection(L, 2) && lua_isinteger(L, 3)) {
      lua_Integer count;
      int needs_pop;
      int data_idx = arraylist_get_collection_data(L, 2, &count, &needs_pop);
      lua_Integer at = lua_tointeger(L, 3);
      arraylist_insert_range(L, obj, at, count);
      lua_getfield(L, obj, "__data");
      for (lua_Integer i = 0; i < count; i++) {
        lua_geti(L, data_idx, i);
        lua_seti(L, -2, at + i);
      }
      lua_pop(L, 1);
      arraylist_update_first_last(L, obj, arraylist_get_size(L, obj));
      if (needs_pop) lua_pop(L, 1);
      return 0;
    }
    if (lua_isinteger(L, 3)) {
      lua_Integer at = lua_tointeger(L, 3);
      arraylist_insert_range(L, obj, at, 1);
      lua_getfield(L, obj, "__data");
      lua_pushvalue(L, 2);
      lua_seti(L, -2, at);
      lua_pop(L, 1);
      arraylist_update_first_last(L, obj, arraylist_get_size(L, obj));
      return 0;
    }
  }
  return luaL_error(L, "ArrayList.add: invalid arguments");
}

static int arraylist_clear (lua_State *L) {
  lua_newtable(L);
  lua_setfield(L, 1, "__data");
  arraylist_set_size(L, 1, 0);
  return 0;
}

static int arraylist_clone (lua_State *L) {
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  {
    int newlist = lua_gettop(L);
    lua_Integer size = arraylist_get_size(L, 1);
    lua_getfield(L, 1, "__data");
    lua_getfield(L, newlist, "__data");
    for (lua_Integer i = 0; i < size; i++) {
      lua_geti(L, -2, i);
      lua_seti(L, -2, i);
    }
    lua_pop(L, 2);
    arraylist_set_capacity(L, newlist, size);
    arraylist_set_size(L, newlist, size);
  }
  return 1;
}

static int arraylist_get (lua_State *L) {
  lua_Integer idx = luaL_checkinteger(L, 2);
  lua_Integer size = arraylist_get_size(L, 1);
  if (idx < 0 || idx >= size) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, 1, "__data");
  lua_geti(L, -1, idx);
  push_option(L, -1);
  return 1;
}

static int arraylist_get_raw_array (lua_State *L) {
  lua_getfield(L, 1, "__data");
  return 1;
}

static int arraylist_is_empty (lua_State *L) {
  lua_pushboolean(L, arraylist_get_size(L, 1) == 0);
  return 1;
}

static int arraylist_iter_index (lua_State *L) {
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

static int arraylist_iter_next (lua_State *L) {
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
  lua_geti(L, -1, idx);
  lua_pushinteger(L, idx);
  lua_setfield(L, 1, "__idx");
  push_option(L, -1);
  return 1;
}

static int arraylist_iterator (lua_State *L) {
  lua_newtable(L);
  lua_getfield(L, 1, "__data");
  lua_setfield(L, -2, "__data");
  lua_pushinteger(L, -1);
  lua_setfield(L, -2, "__idx");
  lua_newtable(L);
  lua_pushcfunction(L, arraylist_iter_next);
  lua_setfield(L, -2, "next");
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, arraylist_iter_index, 1);
  lua_setfield(L, -2, "__index");
  lua_setmetatable(L, -3);
  lua_pop(L, 1);
  return 1;
}

static int arraylist_remove (lua_State *L) {
  if (lua_istable(L, 2)) {
    return arraylist_remove_range(L);
  }
  {
    lua_Integer idx = luaL_checkinteger(L, 2);
    lua_Integer size = arraylist_get_size(L, 1);
    if (idx < 0 || idx >= size)
      return luaL_error(L, "ArrayList index out of bounds");
    lua_getfield(L, 1, "__data");
    lua_geti(L, -1, idx);
    for (lua_Integer i = idx; i < size - 1; i++) {
      lua_geti(L, -2, i + 1);
      lua_seti(L, -3, i);
    }
    lua_pushnil(L);
    lua_seti(L, -3, size - 1);
    lua_pop(L, 1);
    arraylist_set_size(L, 1, size - 1);
    return 1;
  }
}

static int arraylist_remove_range (lua_State *L) {
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_Integer start = 0;
  lua_Integer end = size - 1;
  int inclusive = 1;
  lua_getfield(L, 2, "start");
  if (lua_isinteger(L, -1)) start = lua_tointeger(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "end");
  if (lua_isinteger(L, -1)) end = lua_tointeger(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "hasEnd");
  if (lua_isboolean(L, -1) && !lua_toboolean(L, -1)) end = size - 1;
  lua_pop(L, 1);
  lua_getfield(L, 2, "isClosed");
  if (lua_isboolean(L, -1)) inclusive = lua_toboolean(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "step");
  if (lua_isinteger(L, -1) && lua_tointeger(L, -1) != 1)
    return luaL_error(L, "ArrayList range step must be 1");
  lua_pop(L, 1);
  if (!inclusive) end--;
  if (start < 0 || end >= size || end < start)
    return luaL_error(L, "ArrayList range out of bounds");
  {
    lua_Integer count = end - start + 1;
    lua_getfield(L, 1, "__data");
    for (lua_Integer i = start; i + count < size; i++) {
      lua_geti(L, -1, i + count);
      lua_seti(L, -2, i);
    }
    for (lua_Integer i = size - count; i < size; i++) {
      lua_pushnil(L);
      lua_seti(L, -2, i);
    }
    lua_pop(L, 1);
    arraylist_set_size(L, 1, size - count);
  }
  return 0;
}

static int arraylist_remove_if (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_Integer out = 0;
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 1);
    if (!lua_toboolean(L, -1)) {
      lua_seti(L, -3, out++);
    }
    lua_pop(L, 2);
  }
  for (lua_Integer i = out; i < size; i++) {
    lua_pushnil(L);
    lua_seti(L, -2, i);
  }
  lua_pop(L, 1);
  arraylist_set_size(L, 1, out);
  return 0;
}

static int arraylist_reserve_method (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  arraylist_reserve(L, 1, additional);
  return 0;
}

static int arraylist_reverse (lua_State *L) {
  lua_Integer size = arraylist_get_size(L, 1);
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size / 2; i++) {
    lua_geti(L, -1, i);
    lua_geti(L, -2, size - 1 - i);
    lua_seti(L, -3, i);
    lua_seti(L, -2, size - 1 - i);
  }
  lua_pop(L, 1);
  arraylist_update_first_last(L, 1, size);
  return 0;
}

static int arraylist_slice (lua_State *L) {
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_Integer start = 0;
  lua_Integer end = size - 1;
  int inclusive = 1;
  lua_getfield(L, 2, "start");
  if (lua_isinteger(L, -1)) start = lua_tointeger(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "end");
  if (lua_isinteger(L, -1)) end = lua_tointeger(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "hasEnd");
  if (lua_isboolean(L, -1) && !lua_toboolean(L, -1)) end = size - 1;
  lua_pop(L, 1);
  lua_getfield(L, 2, "isClosed");
  if (lua_isboolean(L, -1)) inclusive = lua_toboolean(L, -1);
  lua_pop(L, 1);
  lua_getfield(L, 2, "step");
  if (lua_isinteger(L, -1) && lua_tointeger(L, -1) != 1)
    return luaL_error(L, "ArrayList range step must be 1");
  lua_pop(L, 1);
  if (!inclusive) end--;
  if (start < 0 || end >= size || end < start)
    return luaL_error(L, "ArrayList range out of bounds");
  {
    lua_Integer count = end - start + 1;
    lua_getglobal(L, "ArrayList");
    lua_call(L, 0, 1);
    lua_getfield(L, 1, "__data");
    lua_getfield(L, -2, "__data");
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, -2, start + i);
      lua_seti(L, -2, i);
    }
    lua_pop(L, 2);
    arraylist_set_capacity(L, -1, count);
    arraylist_set_size(L, -1, count);
  }
  return 1;
}

static int arraylist_to_array (lua_State *L) {
  lua_Integer size = arraylist_get_size(L, 1);
  lua_newtable(L);
  for (lua_Integer i = 0; i < size; i++) {
    lua_getfield(L, 1, "__data");
    lua_geti(L, -1, i);
    lua_seti(L, -3, i);
    lua_pop(L, 1);
  }
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int arraylist_index_of (lua_State *L) {
  lua_Integer size = arraylist_get_size(L, 1);
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    if (lua_compare(L, -1, 2, LUA_OPEQ)) {
      lua_pushinteger(L, i);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pushinteger(L, -1);
  return 1;
}

static int arraylist_contains (lua_State *L) {
  lua_Integer size = arraylist_get_size(L, 1);
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    if (lua_compare(L, -1, 2, LUA_OPEQ)) {
      lua_pushboolean(L, 1);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pushboolean(L, 0);
  return 1;
}

static int arraylist_for_each (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_pushvalue(L, 2);
    lua_geti(L, -2, i);
    lua_call(L, 1, 0);
  }
  lua_pop(L, 1);
  return 0;
}

static int arraylist_map (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  lua_getfield(L, -1, "__data");
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_pushvalue(L, 2);
    lua_geti(L, -2, i);
    lua_call(L, 1, 1);
    lua_seti(L, -3, i);
  }
  lua_pop(L, 2);
  arraylist_set_capacity(L, -1, size);
  arraylist_set_size(L, -1, size);
  return 1;
}

static int arraylist_filter (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = arraylist_get_size(L, 1);
  lua_Integer out = 0;
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  lua_getfield(L, -1, "__data");
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 1);
    if (lua_toboolean(L, -1)) {
      lua_pop(L, 1);
      lua_seti(L, -4, out++);
      continue;
    }
    lua_pop(L, 2);
  }
  lua_pop(L, 2);
  arraylist_set_capacity(L, -1, out);
  arraylist_set_size(L, -1, out);
  return 1;
}

static int arraylist_sort_compare_desc (lua_State *L) {
  lua_pushboolean(L, lua_compare(L, 2, 1, LUA_OPLT));
  return 1;
}

static int arraylist_ordering_lt (lua_State *L, int idx) {
  if (lua_isboolean(L, idx)) return lua_toboolean(L, idx);
  if (lua_isnumber(L, idx)) return lua_tonumber(L, idx) < 0;
  if (lua_isstring(L, idx)) return strcmp(lua_tostring(L, idx), "LT") == 0;
  if (lua_istable(L, idx)) {
    lua_getfield(L, idx, "__tag");
    if (lua_isstring(L, -1)) {
      int lt = strcmp(lua_tostring(L, -1), "LT") == 0;
      lua_pop(L, 1);
      return lt;
    }
    lua_pop(L, 1);
  }
  return 0;
}

static int arraylist_sort_compare (lua_State *L) {
  if (lua_isnil(L, lua_upvalueindex(1))) {
    lua_pushboolean(L, lua_compare(L, 1, 2, LUA_OPLT));
    return 1;
  }
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_pushvalue(L, 1);
  lua_pushvalue(L, 2);
  lua_call(L, 2, 1);
  {
    int lt = arraylist_ordering_lt(L, -1);
    lua_pop(L, 1);
    lua_pushboolean(L, lt);
  }
  return 1;
}

static int arraylist_sort_by (lua_State *L) {
  int comparator_idx = 2;
  if (lua_isboolean(L, 2)) comparator_idx = 3;
  if (!lua_isfunction(L, comparator_idx))
    return luaL_error(L, "ArrayList.sortBy requires comparator");
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "sort");
  lua_getfield(L, 1, "__data");
  lua_pushvalue(L, comparator_idx);
  lua_pushcclosure(L, arraylist_sort_compare, 1);
  lua_call(L, 2, 0);
  lua_pop(L, 1);
  arraylist_update_first_last(L, 1, arraylist_get_size(L, 1));
  return 0;
}

static int arraylist_sort (lua_State *L) {
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "sort");
  lua_getfield(L, 1, "__data");
  lua_pushnil(L);
  lua_pushcclosure(L, arraylist_sort_compare, 1);
  lua_call(L, 2, 0);
  lua_pop(L, 1);
  arraylist_update_first_last(L, 1, arraylist_get_size(L, 1));
  return 0;
}

static int arraylist_sort_desc (lua_State *L) {
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "sort");
  lua_getfield(L, 1, "__data");
  lua_pushcfunction(L, arraylist_sort_compare_desc);
  lua_call(L, 2, 0);
  lua_pop(L, 1);
  arraylist_update_first_last(L, 1, arraylist_get_size(L, 1));
  return 0;
}

static int arraylist_to_string (lua_State *L) {
  lua_Integer size = arraylist_get_size(L, 1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    size_t len;
    const char *s;
    if (i > 0) luaL_addstring(&b, ", ");
    lua_geti(L, -1, i);
    s = luaL_tolstring(L, -1, &len);
    luaL_addlstring(&b, s, len);
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  return 1;
}

static int arraylist_eq (lua_State *L) {
  lua_Integer size1 = arraylist_get_size(L, 1);
  lua_Integer size2 = arraylist_get_size(L, 2);
  if (size1 != size2) {
    lua_pushboolean(L, 0);
    return 1;
  }
  lua_getfield(L, 1, "__data");
  lua_getfield(L, 2, "__data");
  for (lua_Integer i = 0; i < size1; i++) {
    lua_geti(L, -2, i);
    lua_geti(L, -2, i);
    if (!lua_compare(L, -1, -2, LUA_OPEQ)) {
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 2);
  }
  lua_pushboolean(L, 1);
  return 1;
}

static const luaL_Reg arraylist_methods[] = {
  {"add", arraylist_add},
  {"clear", arraylist_clear},
  {"clone", arraylist_clone},
  {"get", arraylist_get},
  {"getRawArray", arraylist_get_raw_array},
  {"isEmpty", arraylist_is_empty},
  {"iterator", arraylist_iterator},
  {"remove", arraylist_remove},
  {"removeRange", arraylist_remove_range},
  {"removeIf", arraylist_remove_if},
  {"reserve", arraylist_reserve_method},
  {"reverse", arraylist_reverse},
  {"slice", arraylist_slice},
  {"sortBy", arraylist_sort_by},
  {"sort", arraylist_sort},
  {"sortDescending", arraylist_sort_desc},
  {"toArray", arraylist_to_array},
  {"toString", arraylist_to_string},
  {"contains", arraylist_contains},
  {"indexOf", arraylist_index_of},
  {"forEach", arraylist_for_each},
  {"map", arraylist_map},
  {"filter", arraylist_filter},
  {"of", arraylist_of},
  {NULL, NULL}
};

int luaB_arraylist_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, arraylist_methods, 0);
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, arraylist_new, 1);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, -2);
  lua_setglobal(L, "ArrayList");
  return 0;
}
