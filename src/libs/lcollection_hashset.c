/*
** HashSet implementation for Cangjie collections.
*/

#define lcollection_hashset_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"

static int hashset_eq (lua_State *L);
static int hashset_to_string (lua_State *L);
static int hashset_union (lua_State *L);
static int hashset_intersect (lua_State *L);
static int hashset_difference (lua_State *L);

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

static int hashset_is_collection (lua_State *L, int idx) {
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

static int hashset_get_collection_data (lua_State *L, int idx, lua_Integer *size, int *needs_pop) {
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

static int hashset_get_map (lua_State *L, int obj) {
  lua_getfield(L, obj, "__map");
  return lua_gettop(L);
}

static lua_Integer hashset_get_size (lua_State *L, int obj) {
  lua_Integer size;
  int map = hashset_get_map(L, obj);
  lua_getfield(L, map, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 2);
  return size;
}

static lua_Integer hashset_get_capacity (lua_State *L, int obj) {
  lua_Integer cap;
  int map = hashset_get_map(L, obj);
  lua_getfield(L, map, "capacity");
  cap = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 2);
  return cap;
}

static void hashset_set_capacity (lua_State *L, int obj, lua_Integer cap) {
  int map = hashset_get_map(L, obj);
  lua_pushinteger(L, cap);
  lua_setfield(L, map, "capacity");
  lua_pop(L, 1);
}

static void hashset_reserve (lua_State *L, int obj, lua_Integer additional) {
  lua_Integer size = hashset_get_size(L, obj);
  lua_Integer cap = hashset_get_capacity(L, obj);
  if (additional <= 0) return;
  if (cap - size >= additional) return;
  {
    lua_Integer target = size + additional;
    lua_Integer grow = (lua_Integer)(cap + cap / 2);
    lua_Integer next = grow > target ? grow : target;
    hashset_set_capacity(L, obj, next);
  }
}

static int hashset_find_key (lua_State *L, int keys_idx, int key_idx, lua_Integer size) {
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

static void hashset_keys_update_size (lua_State *L, int keys_idx, lua_Integer size) {
  lua_pushinteger(L, size);
  lua_setfield(L, keys_idx, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, keys_idx, "size");
}

static int hashset_contains_element (lua_State *L, int set_idx, int key_idx) {
  int abs = lua_absindex(L, set_idx);
  lua_getfield(L, abs, "__map");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 0;
  }
  lua_getfield(L, -1, "__data");
  lua_pushvalue(L, key_idx);
  lua_gettable(L, -2);
  {
    int found = !lua_isnil(L, -1);
    lua_pop(L, 3);
    return found;
  }
}

static int hashset_add_element (lua_State *L, int obj, int key_idx) {
  int map = hashset_get_map(L, obj);
  lua_Integer size;
  lua_getfield(L, map, "__data");
  lua_pushvalue(L, key_idx);
  lua_gettable(L, -2);
  if (!lua_isnil(L, -1)) {
    lua_pop(L, 3);
    return 0;
  }
  lua_pop(L, 1);
  lua_pushvalue(L, key_idx);
  lua_pushboolean(L, 1);
  lua_settable(L, -3);
  lua_getfield(L, map, "__keys");
  size = hashset_get_size(L, obj);
  if (hashset_get_capacity(L, obj) < size + 1)
    hashset_reserve(L, obj, 1);
  lua_pushvalue(L, key_idx);
  lua_seti(L, -2, size);
  hashset_keys_update_size(L, -2, size + 1);
  lua_pushinteger(L, size + 1);
  lua_setfield(L, map, "size");
  lua_pop(L, 3);
  return 1;
}

static int hashset_remove_element (lua_State *L, int obj, int key_idx, int return_option) {
  int map = hashset_get_map(L, obj);
  lua_getfield(L, map, "__data");
  lua_pushvalue(L, key_idx);
  lua_gettable(L, -2);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 3);
    if (return_option) {
      push_none(L);
      return 1;
    }
    return 0;
  }
  lua_pop(L, 1);
  lua_pushvalue(L, key_idx);
  lua_pushnil(L);
  lua_settable(L, -3);
  lua_getfield(L, map, "__keys");
  {
    lua_Integer size = hashset_get_size(L, obj);
    int idx = hashset_find_key(L, -1, key_idx, size);
    if (idx >= 0) {
      for (lua_Integer i = idx; i < size - 1; i++) {
        lua_geti(L, -1, i + 1);
        lua_seti(L, -2, i);
      }
      lua_pushnil(L);
      lua_seti(L, -2, size - 1);
      hashset_keys_update_size(L, -1, size - 1);
      lua_pushinteger(L, size - 1);
      lua_setfield(L, map, "size");
    }
  }
  lua_pop(L, 3);
  if (return_option) {
    push_option(L, key_idx);
    return 1;
  }
  return 0;
}

static int hashset_index (lua_State *L) {
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0 || strcmp(key, "capacity") == 0) {
      int map = hashset_get_map(L, 1);
      lua_getfield(L, map, key);
      lua_remove(L, map);
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

static int hashset_newindex (lua_State *L) {
  return luaL_error(L, "HashSet does not support indexed assignment");
}

static int hashset_new (lua_State *L) {
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
  lua_pushcclosure(L, hashset_index, 1);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, hashset_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_pushcfunction(L, hashset_eq);
  lua_setfield(L, -2, "__eq");
  lua_pushcfunction(L, hashset_to_string);
  lua_setfield(L, -2, "__tostring");
  lua_pushcfunction(L, hashset_intersect);
  lua_setfield(L, -2, "__band");
  lua_pushcfunction(L, hashset_union);
  lua_setfield(L, -2, "__bor");
  lua_pushcfunction(L, hashset_difference);
  lua_setfield(L, -2, "__sub");
  lua_setmetatable(L, obj);
  lua_getglobal(L, "HashMap");
  lua_call(L, 0, 1);
  lua_setfield(L, obj, "__map");
  if (argc == 1) {
    if (lua_isinteger(L, 2)) {
      capacity = lua_tointeger(L, 2);
      luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
    }
    else if (hashset_is_collection(L, 2)) {
      int needs_pop;
      int data_idx = hashset_get_collection_data(L, 2, &size, &needs_pop);
      for (lua_Integer i = 0; i < size; i++) {
        lua_geti(L, data_idx, i);
        hashset_add_element(L, obj, -1);
        lua_pop(L, 1);
      }
      if (needs_pop) lua_pop(L, 1);
      capacity = hashset_get_size(L, obj);
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
      hashset_add_element(L, obj, -1);
      lua_pop(L, 1);
    }
  }
  hashset_set_capacity(L, obj, capacity);
  return 1;
}

static int hashset_add (lua_State *L) {
  if (hashset_is_collection(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashset_get_collection_data(L, 2, &count, &needs_pop);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      hashset_add_element(L, 1, -1);
      lua_pop(L, 1);
    }
    if (needs_pop) lua_pop(L, 1);
    return 0;
  }
  luaL_checkany(L, 2);
  lua_pushboolean(L, hashset_add_element(L, 1, 2));
  return 1;
}

static int hashset_clear (lua_State *L) {
  int map = hashset_get_map(L, 1);
  lua_newtable(L);
  lua_setfield(L, map, "__data");
  lua_newtable(L);
  lua_setfield(L, map, "__keys");
  lua_pushinteger(L, 0);
  lua_setfield(L, map, "size");
  lua_pop(L, 1);
  return 0;
}

static int hashset_clone (lua_State *L) {
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int newset = lua_gettop(L);
    lua_Integer size = hashset_get_size(L, 1);
    int map = hashset_get_map(L, 1);
    lua_getfield(L, map, "__keys");
    for (lua_Integer i = 0; i < size; i++) {
      lua_geti(L, -1, i);
      hashset_add_element(L, newset, -1);
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
  }
  return 1;
}

static int hashset_contains (lua_State *L) {
  if (hashset_is_collection(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashset_get_collection_data(L, 2, &count, &needs_pop);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      if (!hashset_contains_element(L, 1, -1)) {
        lua_pushboolean(L, 0);
        return 1;
      }
      lua_pop(L, 1);
    }
    if (needs_pop) lua_pop(L, 1);
    lua_pushboolean(L, 1);
    return 1;
  }
  {
    lua_pushboolean(L, hashset_contains_element(L, 1, 2));
    return 1;
  }
}

static int hashset_is_empty (lua_State *L) {
  lua_pushboolean(L, hashset_get_size(L, 1) == 0);
  return 1;
}

static int hashset_iterator_index (lua_State *L) {
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

static int hashset_iterator_next (lua_State *L) {
  lua_Integer idx;
  lua_Integer size;
  lua_getfield(L, 1, "__idx");
  idx = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : -1;
  lua_pop(L, 1);
  idx++;
  lua_getfield(L, 1, "__keys");
  lua_getfield(L, -1, "__n");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (idx >= size) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  lua_geti(L, -1, idx);
  lua_setfield(L, 1, "__last");
  lua_pushinteger(L, idx);
  lua_setfield(L, 1, "__idx");
  lua_getfield(L, 1, "__last");
  push_option(L, -1);
  lua_remove(L, -2);
  return 1;
}

static int hashset_iterator_remove (lua_State *L) {
  lua_getfield(L, 1, "__last");
  if (lua_isnil(L, -1)) {
    push_none(L);
    return 1;
  }
  lua_pushvalue(L, -1);
  lua_getfield(L, 1, "__set");
  hashset_remove_element(L, -1, -3, 0);
  lua_pop(L, 1);
  push_none(L);
  lua_setfield(L, 1, "__last");
  push_option(L, -1);
  return 1;
}

static int hashset_iterator (lua_State *L) {
  lua_newtable(L);
  lua_pushvalue(L, 1);
  lua_setfield(L, -2, "__set");
  lua_pushinteger(L, -1);
  lua_setfield(L, -2, "__idx");
  push_none(L);
  lua_setfield(L, -2, "__last");
  lua_getfield(L, 1, "__map");
  lua_getfield(L, -1, "__keys");
  lua_setfield(L, -3, "__keys");
  lua_pop(L, 1);
  lua_newtable(L);
  lua_pushcfunction(L, hashset_iterator_next);
  lua_setfield(L, -2, "next");
  lua_pushcfunction(L, hashset_iterator_remove);
  lua_setfield(L, -2, "remove");
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, hashset_iterator_index, 1);
  lua_setfield(L, -2, "__index");
  lua_setmetatable(L, -3);
  lua_pop(L, 1);
  return 1;
}

static int hashset_remove (lua_State *L) {
  if (hashset_is_collection(L, 2)) {
    int needs_pop;
    lua_Integer count;
    int data_idx = hashset_get_collection_data(L, 2, &count, &needs_pop);
    for (lua_Integer i = 0; i < count; i++) {
      lua_geti(L, data_idx, i);
      hashset_remove_element(L, 1, -1, 0);
      lua_pop(L, 1);
    }
    if (needs_pop) lua_pop(L, 1);
    return 0;
  }
  luaL_checkany(L, 2);
  lua_pushboolean(L, hashset_remove_element(L, 1, 2, 0));
  return 1;
}

static int hashset_remove_if (lua_State *L) {
  luaL_checktype(L, 2, LUA_TFUNCTION);
  lua_Integer size = hashset_get_size(L, 1);
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = size - 1; i >= 0; i--) {
    lua_geti(L, -1, i);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 1);
    if (lua_toboolean(L, -1)) {
      hashset_remove_element(L, 1, -2, 0);
    }
    lua_pop(L, 2);
    if (i == 0) break;
  }
  lua_pop(L, 2);
  return 0;
}

static int hashset_reserve_method (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  hashset_reserve(L, 1, additional);
  return 0;
}

static int hashset_retain (lua_State *L) {
  lua_Integer size = hashset_get_size(L, 1);
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = size - 1; i >= 0; i--) {
    lua_geti(L, -1, i);
    if (!hashset_contains_element(L, 2, -1)) {
      hashset_remove_element(L, 1, -1, 0);
    }
    lua_pop(L, 1);
    if (i == 0) break;
  }
  lua_pop(L, 2);
  return 0;
}

static int hashset_subset_of (lua_State *L) {
  lua_Integer size = hashset_get_size(L, 1);
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    if (!hashset_contains_element(L, 2, -1)) {
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 2);
  lua_pushboolean(L, 1);
  return 1;
}

static int hashset_to_array (lua_State *L) {
  lua_Integer size = hashset_get_size(L, 1);
  lua_newtable(L);
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    lua_geti(L, -1, i);
    lua_seti(L, -3, i);
  }
  lua_pop(L, 2);
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  return 1;
}

static int hashset_union (lua_State *L) {
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int newset = lua_gettop(L);
    lua_Integer size = hashset_get_size(L, 1);
    int map = hashset_get_map(L, 1);
    lua_getfield(L, map, "__keys");
    for (lua_Integer i = 0; i < size; i++) {
      lua_geti(L, -1, i);
      hashset_add_element(L, newset, -1);
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
    if (lua_istable(L, 2)) {
      size = hashset_get_size(L, 2);
      map = hashset_get_map(L, 2);
      lua_getfield(L, map, "__keys");
      for (lua_Integer i = 0; i < size; i++) {
        lua_geti(L, -1, i);
        hashset_add_element(L, newset, -1);
        lua_pop(L, 1);
      }
      lua_pop(L, 2);
    }
  }
  return 1;
}

static int hashset_intersect (lua_State *L) {
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int newset = lua_gettop(L);
    if (lua_istable(L, 2)) {
      lua_Integer size = hashset_get_size(L, 1);
      int map = hashset_get_map(L, 1);
      lua_getfield(L, map, "__keys");
      for (lua_Integer i = 0; i < size; i++) {
        lua_geti(L, -1, i);
        if (hashset_contains_element(L, 2, -1)) {
          hashset_add_element(L, newset, -1);
        }
        lua_pop(L, 1);
      }
      lua_pop(L, 2);
    }
  }
  return 1;
}

static int hashset_difference (lua_State *L) {
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int newset = lua_gettop(L);
    lua_Integer size = hashset_get_size(L, 1);
    int map = hashset_get_map(L, 1);
    lua_getfield(L, map, "__keys");
    for (lua_Integer i = 0; i < size; i++) {
      lua_geti(L, -1, i);
      if (!hashset_contains_element(L, 2, -1)) {
        hashset_add_element(L, newset, -1);
      }
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
  }
  return 1;
}

static int hashset_to_string (lua_State *L) {
  lua_Integer size = hashset_get_size(L, 1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = 0; i < size; i++) {
    size_t len;
    const char *s;
    if (i > 0) luaL_addstring(&b, ", ");
    lua_geti(L, -1, i);
    s = luaL_tolstring(L, -1, &len);
    luaL_addlstring(&b, s, len);
    lua_pop(L, 2);
  }
  lua_pop(L, 2);
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  return 1;
}

static int hashset_eq (lua_State *L) {
  lua_Integer size1 = hashset_get_size(L, 1);
  lua_Integer size2 = hashset_get_size(L, 2);
  if (size1 != size2) {
    lua_pushboolean(L, 0);
    return 1;
  }
  int map = hashset_get_map(L, 1);
  lua_getfield(L, map, "__keys");
  for (lua_Integer i = 0; i < size1; i++) {
    lua_geti(L, -1, i);
    if (!hashset_contains_element(L, 2, -1)) {
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 2);
  lua_pushboolean(L, 1);
  return 1;
}

static const luaL_Reg hashset_methods[] = {
  {"add", hashset_add},
  {"clear", hashset_clear},
  {"clone", hashset_clone},
  {"contains", hashset_contains},
  {"isEmpty", hashset_is_empty},
  {"iterator", hashset_iterator},
  {"remove", hashset_remove},
  {"removeIf", hashset_remove_if},
  {"reserve", hashset_reserve_method},
  {"retain", hashset_retain},
  {"subsetOf", hashset_subset_of},
  {"toArray", hashset_to_array},
  {"toString", hashset_to_string},
  {"__band", hashset_intersect},
  {"__bor", hashset_union},
  {"__sub", hashset_difference},
  {NULL, NULL}
};

int luaB_hashset_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, hashset_methods, 0);
  lua_newtable(L);
  lua_pushvalue(L, -2);
  lua_pushcclosure(L, hashset_new, 1);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, -2);
  lua_setglobal(L, "HashSet");
  return 0;
}
