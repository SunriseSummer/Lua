/*
** HashMap implementation for Cangjie collections.
*/

#define lcollection_hashmap_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"

static int hashmap_eq (lua_State *L);
static int hashmap_to_string (lua_State *L);

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

static void push_tuple (lua_State *L, int key_idx, int value_idx) {
  lua_newtable(L);
  lua_pushvalue(L, key_idx);
  lua_rawseti(L, -2, 0);
  lua_pushvalue(L, value_idx);
  lua_rawseti(L, -2, 1);
  lua_pushinteger(L, 2);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, 2);
  lua_setfield(L, -2, "size");
  lua_pushboolean(L, 1);
  lua_setfield(L, -2, "__tuple");
}

static lua_Integer hashmap_get_size (lua_State *L, int obj) {
  lua_Integer size;
  lua_getfield(L, obj, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return size;
}

static void hashmap_set_size (lua_State *L, int obj, lua_Integer size) {
  lua_pushinteger(L, size);
  lua_setfield(L, obj, "size");
}

static lua_Integer hashmap_get_capacity (lua_State *L, int obj) {
  lua_Integer cap;
  lua_getfield(L, obj, "capacity");
  cap = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  return cap;
}

static void hashmap_set_capacity (lua_State *L, int obj, lua_Integer cap) {
  lua_pushinteger(L, cap);
  lua_setfield(L, obj, "capacity");
}

static void hashmap_keys_update_size (lua_State *L, int keys_idx, lua_Integer size) {
  lua_pushinteger(L, size);
  lua_setfield(L, keys_idx, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, keys_idx, "size");
}

static int hashmap_get_collection_data (lua_State *L, int idx, lua_Integer *size, int *needs_pop) {
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

static int hashmap_find_key (lua_State *L, int keys_idx, int key_idx, lua_Integer size) {
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, keys_idx, i);
    if (lua_compare(L, -1, key_idx, LUA_OPEQ)) {
      lua_pop(L, 1);
      return (int)i;
    }
    lua_pop(L, 1);
  }
  return -1;
}

static void hashmap_reserve (lua_State *L, int obj, lua_Integer additional) {
  lua_Integer size = hashmap_get_size(L, obj);
  lua_Integer cap = hashmap_get_capacity(L, obj);
  if (additional <= 0) return;
  if (cap - size >= additional) return;
  {
    lua_Integer target = size + additional;
    lua_Integer grow = (lua_Integer)(cap + cap / 2);
    lua_Integer next = grow > target ? grow : target;
    hashmap_set_capacity(L, obj, next);
  }
}

static int hashmap_get_data (lua_State *L, int obj) {
  lua_getfield(L, obj, "__data");
  return lua_gettop(L);
}

static int hashmap_get_keys (lua_State *L, int obj) {
  lua_getfield(L, obj, "__keys");
  return lua_gettop(L);
}

static void hashmap_append_key (lua_State *L, int obj, int key_idx) {
  int keys_idx;
  lua_Integer size = hashmap_get_size(L, obj);
  if (hashmap_get_capacity(L, obj) < size + 1)
    hashmap_reserve(L, obj, 1);
  keys_idx = hashmap_get_keys(L, obj);
  lua_pushvalue(L, key_idx);
  lua_seti(L, keys_idx, size);
  hashmap_keys_update_size(L, keys_idx, size + 1);
  hashmap_set_size(L, obj, size + 1);
  lua_pop(L, 1);
}

static int hashmap_remove_key (lua_State *L, int obj, int key_idx, int return_old) {
  int data_idx = hashmap_get_data(L, obj);
  lua_pushvalue(L, key_idx);
  lua_gettable(L, data_idx);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    lua_pop(L, 1);
    if (return_old) {
      push_none(L);
      return 1;
    }
    return 0;
  }
  if (return_old) {
    push_option(L, -1);
    lua_replace(L, -2);
  }
  lua_pushvalue(L, key_idx);
  lua_pushnil(L);
  lua_settable(L, data_idx);
  lua_pop(L, 1);
  {
    int keys_idx = hashmap_get_keys(L, obj);
    lua_Integer size = hashmap_get_size(L, obj);
    int idx = hashmap_find_key(L, keys_idx, key_idx, size);
    if (idx >= 0) {
      for (lua_Integer i = idx; i < size - 1; i++) {
        lua_geti(L, keys_idx, i + 1);
        lua_seti(L, keys_idx, i);
      }
      lua_pushnil(L);
      lua_seti(L, keys_idx, size - 1);
      hashmap_keys_update_size(L, keys_idx, size - 1);
      hashmap_set_size(L, obj, size - 1);
    }
    lua_pop(L, 1);
  }
  return return_old ? 1 : 0;
}

static int hashmap_put_value (lua_State *L, int obj, int key_idx, int value_idx, int allow_new, int return_old, int replace_only) {
  int data_idx = hashmap_get_data(L, obj);
  lua_pushvalue(L, key_idx);
  lua_gettable(L, data_idx);
  if (!lua_isnil(L, -1)) {
    if (return_old) {
      push_option(L, -1);
      lua_replace(L, -2);
    }
    lua_pushvalue(L, key_idx);
    lua_pushvalue(L, value_idx);
    lua_settable(L, data_idx);
    lua_pop(L, 1);
    return return_old ? 1 : 0;
  }
  lua_pop(L, 1);
  if (!allow_new || replace_only) {
    lua_pop(L, 1);
    if (return_old) {
      push_none(L);
      return 1;
    }
    return 0;
  }
  lua_pushvalue(L, key_idx);
  lua_pushvalue(L, value_idx);
  lua_settable(L, data_idx);
  lua_pop(L, 1);
  hashmap_append_key(L, obj, key_idx);
  if (return_old) {
    push_none(L);
    return 1;
  }
  return 0;
}

static int hashmap_index (lua_State *L) {
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0 || strcmp(key, "capacity") == 0) {
      lua_getfield(L, 1, key);
      return 1;
    }
    lua_pushvalue(L, 2);
    lua_rawget(L, lua_upvalueindex(1));
    if (lua_isfunction(L, -1)) {
      lua_pushvalue(L, -1);
      lua_pushvalue(L, 1);
      lua_pushcclosure(L, cangjie_bound_method, 2);
      return 1;
    }
    if (!lua_isnil(L, -1)) return 1;
    lua_pop(L, 1);
  }
  {
    int data_idx = hashmap_get_data(L, 1);
    lua_pushvalue(L, 2);
    lua_gettable(L, data_idx);
    lua_remove(L, data_idx);
    if (lua_isnil(L, -1))
      return luaL_error(L, "HashMap key not found");
    return 1;
  }
}

static int hashmap_newindex (lua_State *L) {
  return hashmap_put_value(L, 1, 2, 3, 1, 0, 0);
}

static int hashmap_new (lua_State *L) {
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
  lua_pushcclosure(L, hashmap_index, 1);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, hashmap_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_pushcfunction(L, hashmap_eq);
  lua_setfield(L, -2, "__eq");
  lua_pushcfunction(L, hashmap_to_string);
  lua_setfield(L, -2, "__tostring");
  lua_setmetatable(L, obj);
  lua_newtable(L);
  lua_setfield(L, obj, "__data");
  lua_newtable(L);
  lua_setfield(L, obj, "__keys");
  if (argc == 1) {
    if (lua_isinteger(L, 2)) {
      capacity = lua_tointeger(L, 2);
      luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
    }
    else {
      int needs_pop;
      int data_idx = hashmap_get_collection_data(L, 2, &size, &needs_pop);
      for (lua_Integer i = 0; i < size; i++) {
        lua_geti(L, data_idx, i);
        lua_geti(L, -1, 0);
        lua_geti(L, -2, 1);
        hashmap_put_value(L, obj, -2, -1, 1, 0, 0);
        lua_pop(L, 3);
      }
      if (needs_pop) lua_pop(L, 1);
      capacity = size;
    }
  }
  else if (argc >= 2 && lua_isinteger(L, 2)) {
    size = lua_tointeger(L, 2);
    luaL_argcheck(L, size >= 0, 2, "size must be non-negative");
    capacity = size;
    for (lua_Integer i = 0; i < size; i++) {
      lua_pushvalue(L, 3);
      lua_pushinteger(L, i);
      lua_call(L, 1, 1);
      lua_geti(L, -1, 0);
      lua_geti(L, -2, 1);
      hashmap_put_value(L, obj, -2, -1, 1, 0, 0);
      lua_pop(L, 3);
    }
  }
  size = hashmap_get_size(L, obj);
  hashmap_set_capacity(L, obj, capacity);
  hashmap_set_size(L, obj, size);
  return 1;
}

static int hashmap_add (lua_State *L) {
  int nargs = lua_gettop(L) - 1;
  if (nargs == 1 && lua_istable(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashmap_get_collection_data(L, 2, &count, &needs_pop);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      lua_geti(L, -1, 0);
      lua_geti(L, -2, 1);
      hashmap_put_value(L, 1, -2, -1, 1, 0, 0);
      lua_pop(L, 3);
    }
    if (needs_pop) lua_pop(L, 1);
    return 0;
  }
  if (nargs < 2) return luaL_error(L, "HashMap.add requires key and value");
  return hashmap_put_value(L, 1, 2, 3, 1, 1, 0);
}

static int hashmap_add_if_absent (lua_State *L) {
  return hashmap_put_value(L, 1, 2, 3, 1, 1, 1);
}

static int hashmap_replace (lua_State *L) {
  return hashmap_put_value(L, 1, 2, 3, 0, 1, 1);
}

static int hashmap_clear (lua_State *L) {
  lua_newtable(L);
  lua_setfield(L, 1, "__data");
  lua_newtable(L);
  lua_setfield(L, 1, "__keys");
  hashmap_set_size(L, 1, 0);
  return 0;
}

static int hashmap_clone (lua_State *L) {
  lua_getglobal(L, "HashMap");
  lua_call(L, 0, 1);
  {
    int newmap = lua_gettop(L);
    lua_Integer size = hashmap_get_size(L, 1);
    int keys_idx = hashmap_get_keys(L, 1);
    int data_idx = hashmap_get_data(L, 1);
    for (lua_Integer i = 0; i < size; i++) {
      lua_geti(L, keys_idx, i);
      lua_pushvalue(L, -1);
      lua_gettable(L, data_idx);
      hashmap_put_value(L, newmap, -2, -1, 1, 0, 0);
      lua_pop(L, 2);
    }
    lua_pop(L, 2);
    hashmap_set_size(L, newmap, size);
    hashmap_set_capacity(L, newmap, hashmap_get_capacity(L, 1));
  }
  return 1;
}

static int hashmap_contains (lua_State *L) {
  int nargs = lua_gettop(L) - 1;
  if (nargs == 1 && lua_istable(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashmap_get_collection_data(L, 2, &count, &needs_pop);
    int map_data = hashmap_get_data(L, 1);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      lua_pushvalue(L, -1);
      lua_gettable(L, map_data);
      if (lua_isnil(L, -1)) {
        lua_pushboolean(L, 0);
        return 1;
      }
      lua_pop(L, 2);
    }
    lua_pop(L, 1);
    if (needs_pop) lua_pop(L, 1);
    lua_pushboolean(L, 1);
    return 1;
  }
  {
    int data_idx = hashmap_get_data(L, 1);
    lua_pushvalue(L, 2);
    lua_gettable(L, data_idx);
    lua_pushboolean(L, !lua_isnil(L, -1));
    return 1;
  }
}

static int hashmap_entryview_index (lua_State *L) {
  if (lua_type(L, 2) == LUA_TSTRING && strcmp(lua_tostring(L, 2), "value") == 0) {
    lua_getfield(L, 1, "__map");
    lua_getfield(L, -1, "__data");
    lua_getfield(L, 1, "key");
    lua_gettable(L, -2);
    push_option(L, -1);
    return 1;
  }
  lua_pushvalue(L, 2);
  lua_rawget(L, 1);
  return 1;
}

static int hashmap_entryview_newindex (lua_State *L) {
  if (lua_type(L, 2) == LUA_TSTRING && strcmp(lua_tostring(L, 2), "value") == 0) {
    lua_getfield(L, 1, "__map");
    lua_getfield(L, 1, "key");
    if (cangjie_has_tag(L, 3, "None") || lua_isnil(L, 3)) {
      hashmap_remove_key(L, -2, -1, 0);
      return 0;
    }
    if (cangjie_has_tag(L, 3, "Some")) {
      lua_rawgeti(L, 3, 1);
      hashmap_put_value(L, -3, -2, -1, 1, 0, 0);
      lua_pop(L, 1);
      return 0;
    }
    lua_pushvalue(L, 3);
    hashmap_put_value(L, -3, -2, -1, 1, 0, 0);
    lua_pop(L, 1);
    return 0;
  }
  lua_rawset(L, 1);
  return 0;
}

static int hashmap_entry_view (lua_State *L) {
  lua_newtable(L);
  lua_pushvalue(L, 2);
  lua_setfield(L, -2, "key");
  lua_pushvalue(L, 1);
  lua_setfield(L, -2, "__map");
  lua_newtable(L);
  lua_pushcfunction(L, hashmap_entryview_index);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, hashmap_entryview_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_setmetatable(L, -2);
  return 1;
}

static int hashmap_get (lua_State *L) {
  int data_idx = hashmap_get_data(L, 1);
  lua_pushvalue(L, 2);
  lua_gettable(L, data_idx);
  push_option(L, -1);
  return 1;
}

static int hashmap_is_empty (lua_State *L) {
  lua_pushboolean(L, hashmap_get_size(L, 1) == 0);
  return 1;
}

static int hashmap_iterator_index (lua_State *L) {
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

static int hashmap_iterator_next (lua_State *L) {
  lua_Integer idx;
  lua_Integer size;
  lua_getfield(L, 1, "__idx");
  idx = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : -1;
  lua_pop(L, 1);
  idx++;
  lua_getfield(L, 1, "__map");
  size = hashmap_get_size(L, -1);
  if (idx >= size) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, -1, "__keys");
  lua_geti(L, -1, idx);
  lua_setfield(L, 1, "__last_key");
  lua_pushinteger(L, idx);
  lua_setfield(L, 1, "__idx");
  lua_getfield(L, -2, "__data");
  lua_getfield(L, 1, "__last_key");
  lua_gettable(L, -2);
  lua_pushvalue(L, -1);
  lua_setfield(L, 1, "__last_value");
  lua_getfield(L, 1, "__last_key");
  push_tuple(L, -1, -2);
  push_option(L, -1);
  return 1;
}

static int hashmap_iterator_remove (lua_State *L) {
  lua_getfield(L, 1, "__last_key");
  if (lua_isnil(L, -1)) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, 1, "__last_value");
  lua_getfield(L, 1, "__map");
  hashmap_remove_key(L, -1, -3, 0);
  push_none(L);
  lua_setfield(L, 1, "__last_key");
  push_none(L);
  lua_setfield(L, 1, "__last_value");
  push_tuple(L, -3, -2);
  push_option(L, -1);
  return 1;
}

static int hashmap_iterator (lua_State *L) {
  lua_newtable(L);
  lua_pushvalue(L, 1);
  lua_setfield(L, -2, "__map");
  lua_pushinteger(L, -1);
  lua_setfield(L, -2, "__idx");
  push_none(L);
  lua_setfield(L, -2, "__last_key");
  lua_newtable(L);
  lua_pushcfunction(L, hashmap_iterator_next);
  lua_setfield(L, -2, "next");
  lua_pushcfunction(L, hashmap_iterator_remove);
  lua_setfield(L, -2, "remove");
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, hashmap_iterator_index, 1);
  lua_setfield(L, -2, "__index");
  lua_setmetatable(L, -3);
  lua_pop(L, 1);
  return 1;
}

static int hashmap_keys (lua_State *L) {
  lua_Integer size = hashmap_get_size(L, 1);
  lua_newtable(L);
  lua_getfield(L, 1, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_seti(L, -3, i);
  }
  lua_pop(L, 1);
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int hashmap_values (lua_State *L) {
  lua_Integer size = hashmap_get_size(L, 1);
  lua_newtable(L);
  lua_getfield(L, 1, "__data");
  lua_getfield(L, 1, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_pushvalue(L, -1);
    lua_gettable(L, -3);
    lua_seti(L, -5, i);
    lua_pop(L, 1);
  }
  lua_pop(L, 2);
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int hashmap_remove (lua_State *L) {
  int nargs = lua_gettop(L) - 1;
  if (nargs == 1 && lua_istable(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashmap_get_collection_data(L, 2, &count, &needs_pop);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      hashmap_remove_key(L, 1, -1, 0);
      lua_pop(L, 1);
    }
    if (needs_pop) lua_pop(L, 1);
    return 0;
  }
  return hashmap_remove_key(L, 1, 2, 1);
}

static int hashmap_remove_if (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = hashmap_get_size(L, 1);
  int keys_idx = hashmap_get_keys(L, 1);
  int data_idx = hashmap_get_data(L, 1);
  for (lua_Integer i = size - 1; i >= 0; i--) {
    lua_geti(L, keys_idx, i);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, -2);
    lua_gettable(L, data_idx);
    lua_call(L, 2, 1);
    if (lua_toboolean(L, -1)) {
      hashmap_remove_key(L, 1, -2, 0);
    }
    lua_pop(L, 2);
    if (i == 0) break;
  }
  lua_pop(L, 2);
  return 0;
}

static int hashmap_reserve_method (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  hashmap_reserve(L, 1, additional);
  return 0;
}

static int hashmap_to_array (lua_State *L) {
  lua_Integer size = hashmap_get_size(L, 1);
  lua_newtable(L);
  lua_getfield(L, 1, "__data");
  lua_getfield(L, 1, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_pushvalue(L, -1);
    lua_gettable(L, -3);
    push_tuple(L, -2, -1);
    lua_seti(L, -6, i);
    lua_pop(L, 2);
  }
  lua_pop(L, 2);
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int hashmap_eq (lua_State *L) {
  lua_Integer size1 = hashmap_get_size(L, 1);
  lua_Integer size2 = hashmap_get_size(L, 2);
  if (size1 != size2) {
    lua_pushboolean(L, 0);
    return 1;
  }
  {
    int keys_idx = hashmap_get_keys(L, 1);
    int data_idx = hashmap_get_data(L, 1);
    int other_data = hashmap_get_data(L, 2);
    for (lua_Integer i = 0; i < size1; i++) {
      lua_geti(L, keys_idx, i);
      lua_pushvalue(L, -1);
      lua_gettable(L, data_idx);
      lua_pushvalue(L, -2);
      lua_gettable(L, other_data);
      if (!lua_compare(L, -1, -2, LUA_OPEQ)) {
        lua_pushboolean(L, 0);
        return 1;
      }
      lua_pop(L, 3);
    }
    lua_pop(L, 3);
  }
  lua_pushboolean(L, 1);
  return 1;
}

static int hashmap_to_string (lua_State *L) {
  lua_Integer size = hashmap_get_size(L, 1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  lua_getfield(L, 1, "__keys");
  lua_getfield(L, 1, "__data");
  for (lua_Integer i = 0; i < size; i++) {
    size_t len;
    const char *s;
    if (i > 0) luaL_addstring(&b, ", ");
    lua_geti(L, -2, i);
    lua_pushvalue(L, -1);
    lua_gettable(L, -3);
    luaL_addchar(&b, '(');
    s = luaL_tolstring(L, -2, &len);
    luaL_addlstring(&b, s, len);
    lua_pop(L, 1);
    luaL_addstring(&b, ", ");
    s = luaL_tolstring(L, -1, &len);
    luaL_addlstring(&b, s, len);
    lua_pop(L, 1);
    luaL_addchar(&b, ')');
    lua_pop(L, 2);
  }
  lua_pop(L, 2);
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  return 1;
}

static const luaL_Reg hashmap_methods[] = {
  {"add", hashmap_add},
  {"addIfAbsent", hashmap_add_if_absent},
  {"clear", hashmap_clear},
  {"clone", hashmap_clone},
  {"contains", hashmap_contains},
  {"entryView", hashmap_entry_view},
  {"get", hashmap_get},
  {"isEmpty", hashmap_is_empty},
  {"iterator", hashmap_iterator},
  {"keys", hashmap_keys},
  {"remove", hashmap_remove},
  {"removeIf", hashmap_remove_if},
  {"replace", hashmap_replace},
  {"reserve", hashmap_reserve_method},
  {"toArray", hashmap_to_array},
  {"toString", hashmap_to_string},
  {"values", hashmap_values},
  {NULL, NULL}
};

int luaB_hashmap_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, hashmap_methods, 0);
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, hashmap_new, 1);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, -2);
  lua_setglobal(L, "HashMap");
  return 0;
}
