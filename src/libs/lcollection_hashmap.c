/*
** HashMap implementation for Cangjie collection package.
*/

#define lcollection_hashmap_c
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

static int is_none (lua_State *L, int idx) {
  return cangjie_has_tag(L, idx, "None");
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

static lua_Integer collection_size (lua_State *L, int idx) {
  lua_Integer size = get_int_field(L, idx, "size", -1);
  if (size >= 0)
    return size;
  size = get_int_field(L, idx, "__n", -1);
  if (size >= 0)
    return size;
  return 0;
}

static int is_collection (lua_State *L, int idx) {
  if (!lua_istable(L, idx))
    return 0;
  if (get_int_field(L, idx, "size", -1) >= 0)
    return 1;
  if (get_int_field(L, idx, "__n", -1) >= 0)
    return 1;
  return 0;
}

static int get_data_table (lua_State *L, int self) {
  self = lua_absindex(L, self);
  lua_pushliteral(L, "__data");
  lua_rawget(L, self);
  if (lua_istable(L, -1))
    return lua_gettop(L);
  lua_pop(L, 1);
  lua_newtable(L);
  lua_pushliteral(L, "__data");
  lua_pushvalue(L, -2);
  lua_rawset(L, self);
  return lua_gettop(L);
}

static int get_keys_table (lua_State *L, int self) {
  self = lua_absindex(L, self);
  lua_pushliteral(L, "__keys");
  lua_rawget(L, self);
  if (lua_istable(L, -1))
    return lua_gettop(L);
  lua_pop(L, 1);
  lua_newtable(L);
  lua_pushliteral(L, "__keys");
  lua_pushvalue(L, -2);
  lua_rawset(L, self);
  return lua_gettop(L);
}

static void set_size (lua_State *L, int self, lua_Integer size) {
  self = lua_absindex(L, self);
  lua_pushinteger(L, size);
  lua_pushliteral(L, "size");
  lua_insert(L, -2);
  lua_rawset(L, self);
}

static void ensure_capacity (lua_State *L, int self, lua_Integer needed) {
  lua_Integer capacity = get_int_field(L, self, "capacity", 0);
  if (needed <= capacity)
    return;
  {
    lua_Integer grow = (capacity * 3) / 2;
    if (grow < needed)
      grow = needed;
    if (grow < 1)
      grow = 1;
    lua_pushinteger(L, grow);
    lua_pushliteral(L, "capacity");
    lua_insert(L, -2);
    lua_rawset(L, self);
  }
}


static int find_key_index (lua_State *L, int keys_idx, int key_idx,
                           lua_Integer size) {
  lua_Integer i;
  keys_idx = lua_absindex(L, keys_idx);
  key_idx = lua_absindex(L, key_idx);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    if (lua_rawequal(L, -1, key_idx)) {
      lua_pop(L, 1);
      return (int)i;
    }
    lua_pop(L, 1);
  }
  return -1;
}


static int hashmap_fetch_value (lua_State *L, int data_idx, int key_idx) {
  data_idx = lua_absindex(L, data_idx);
  key_idx = lua_absindex(L, key_idx);
  lua_pushvalue(L, key_idx);
  lua_rawget(L, data_idx);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    return 0;
  }
  return 1;
}


static void hashmap_store_value (lua_State *L, int data_idx,
                                 int key_idx, int value_idx) {
  data_idx = lua_absindex(L, data_idx);
  key_idx = lua_absindex(L, key_idx);
  value_idx = lua_absindex(L, value_idx);
  lua_pushvalue(L, key_idx);
  lua_pushvalue(L, value_idx);
  lua_rawset(L, data_idx);
}


static void hashmap_insert_new (lua_State *L, int self, int data_idx,
                                int keys_idx, int key_idx, int value_idx) {
  lua_Integer size = get_int_field(L, self, "size", 0);
  ensure_capacity(L, self, size + 1);
  lua_pushvalue(L, key_idx);
  lua_rawseti(L, keys_idx, size);
  hashmap_store_value(L, data_idx, key_idx, value_idx);
  set_size(L, self, size + 1);
}


static void hashmap_add_entry (lua_State *L, int self, int data_idx,
                               int keys_idx, int key_idx, int value_idx) {
  if (hashmap_fetch_value(L, data_idx, key_idx)) {
    lua_pop(L, 1);
    hashmap_store_value(L, data_idx, key_idx, value_idx);
  }
  else {
    hashmap_insert_new(L, self, data_idx, keys_idx, key_idx, value_idx);
  }
}


static int hashmap_get_map_tables (lua_State *L, int idx,
                                   int *keys_idx, int *data_idx) {
  idx = lua_absindex(L, idx);
  lua_pushliteral(L, "__keys");
  lua_rawget(L, idx);
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 0;
  }
  lua_pushliteral(L, "__data");
  lua_rawget(L, idx);
  if (!lua_istable(L, -1)) {
    lua_pop(L, 2);
    return 0;
  }
  *keys_idx = lua_gettop(L) - 1;
  *data_idx = lua_gettop(L);
  return 1;
}


static void hashmap_add_collection (lua_State *L, int self, int data_idx,
                                    int keys_idx, int collection_idx) {
  int map_keys;
  int map_data;
  collection_idx = lua_absindex(L, collection_idx);
  if (hashmap_get_map_tables(L, collection_idx, &map_keys, &map_data)) {
    lua_Integer i;
    lua_Integer count = get_int_field(L, collection_idx, "size", 0);
    for (i = 0; i < count; i++) {
      lua_rawgeti(L, map_keys, i);
      lua_pushvalue(L, -1);
      lua_rawget(L, map_data);
      hashmap_add_entry(L, self, data_idx, keys_idx, -2, -1);
      lua_pop(L, 2);
    }
    lua_pop(L, 2);
    return;
  }
  {
    lua_Integer i;
    lua_Integer count = collection_size(L, collection_idx);
    for (i = 0; i < count; i++) {
      lua_rawgeti(L, collection_idx, i);
      if (lua_istable(L, -1)) {
        lua_rawgeti(L, -1, 0);
        lua_rawgeti(L, -2, 1);
        hashmap_add_entry(L, self, data_idx, keys_idx, -2, -1);
        lua_pop(L, 2);
      }
      lua_pop(L, 1);
    }
  }
}


static int hashmap_remove_key_internal (lua_State *L, int self, int key_idx,
                                        int push_old) {
  key_idx = lua_absindex(L, key_idx);
  {
    int data_idx = lua_absindex(L, get_data_table(L, self));
    int keys_idx = lua_absindex(L, get_keys_table(L, self));
  lua_Integer size = get_int_field(L, self, "size", 0);
  int key_index;
    if (!hashmap_fetch_value(L, data_idx, key_idx)) {
      lua_remove(L, keys_idx);
      lua_remove(L, data_idx);
      if (push_old) {
        push_none(L);
        return 1;
      }
      return 0;
    }
    if (push_old) {
      push_some(L, -1);
      lua_remove(L, -2);  /* drop raw value, keep Some */
    }
    else {
      lua_pop(L, 1);
    }
    lua_pushvalue(L, key_idx);
    lua_pushnil(L);
    lua_rawset(L, data_idx);
    key_index = find_key_index(L, keys_idx, key_idx, size);
    if (key_index >= 0) {
      lua_Integer i;
      for (i = key_index + 1; i < size; i++) {
        lua_rawgeti(L, keys_idx, i);
        lua_rawseti(L, keys_idx, i - 1);
      }
      lua_pushnil(L);
      lua_rawseti(L, keys_idx, size - 1);
      set_size(L, self, size - 1);
    }
    lua_remove(L, keys_idx);
    lua_remove(L, data_idx);
  }
  return push_old ? 1 : 0;
}


static void push_tuple (lua_State *L, int key_idx, int value_idx) {
  key_idx = lua_absindex(L, key_idx);
  value_idx = lua_absindex(L, value_idx);
  lua_newtable(L);
  lua_pushvalue(L, key_idx);
  lua_rawseti(L, -2, 0);
  lua_pushvalue(L, value_idx);
  lua_rawseti(L, -2, 1);
  lua_pushinteger(L, 2);
  lua_setfield(L, -2, "__n");
  lua_pushboolean(L, 1);
  lua_setfield(L, -2, "__tuple");
}

static int hashmap_init (lua_State *L) {
  int self = 1;
  int nargs = lua_gettop(L) - 1;
  int data_idx = get_data_table(L, self);
  int keys_idx = get_keys_table(L, self);
  lua_Integer size = 0;
  lua_Integer capacity = 16;
  if (nargs == 0) {
    capacity = 16;
  }
  else if (nargs == 1) {
    if (lua_isinteger(L, 2)) {
      capacity = lua_tointeger(L, 2);
      luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
    }
    else if (lua_istable(L, 2)) {
      lua_Integer i;
      lua_Integer count = collection_size(L, 2);
      for (i = 0; i < count; i++) {
        lua_rawgeti(L, 2, i);
        if (lua_istable(L, -1)) {
          lua_rawgeti(L, -1, 0);
          lua_rawgeti(L, -2, 1);
          lua_rawset(L, data_idx);
          lua_rawseti(L, keys_idx, size++);
        }
        lua_pop(L, 1);
      }
      capacity = size > 16 ? size : 16;
    }
  }
  else if (nargs == 2) {
    if (lua_isinteger(L, 2) && lua_isfunction(L, 3)) {
      lua_Integer i;
      size = lua_tointeger(L, 2);
      luaL_argcheck(L, size >= 0, 2, "size must be non-negative");
      for (i = 0; i < size; i++) {
        lua_pushvalue(L, 3);
        lua_pushinteger(L, i);
        lua_call(L, 1, 1);
        if (lua_istable(L, -1)) {
          lua_rawgeti(L, -1, 0);
          lua_rawgeti(L, -2, 1);
          lua_rawset(L, data_idx);
          lua_rawseti(L, keys_idx, i);
        }
        lua_pop(L, 1);
      }
      capacity = size > 16 ? size : 16;
    }
  }
  lua_pushinteger(L, capacity);
  lua_pushliteral(L, "capacity");
  lua_insert(L, -2);
  lua_rawset(L, self);
  set_size(L, self, size);
  lua_pop(L, 2);
  return 0;
}

static int hashmap_add (lua_State *L) {
  int self = 1;
  int nargs = lua_gettop(L) - 1;
  int data_idx = get_data_table(L, self);
  int keys_idx = get_keys_table(L, self);
  if (nargs == 1 && lua_istable(L, 2)) {
    hashmap_add_collection(L, self, data_idx, keys_idx, 2);
    lua_pop(L, 2);
    return 0;
  }
  if (nargs != 2) {
    return luaL_error(L, "HashMap.add expects 1 or 2 arguments");
  }
  if (hashmap_fetch_value(L, data_idx, 2)) {
    push_some(L, -1);
    lua_remove(L, -2);
    hashmap_store_value(L, data_idx, 2, 3);
    lua_pop(L, 2);
    return 1;
  }
  hashmap_insert_new(L, self, data_idx, keys_idx, 2, 3);
  lua_pop(L, 2);
  push_none(L);
  return 1;
}

static int hashmap_replace (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  if (!hashmap_fetch_value(L, data_idx, 2)) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  push_some(L, -1);
  lua_remove(L, -2);
  hashmap_store_value(L, data_idx, 2, 3);
  lua_remove(L, data_idx);
  return 1;
}

static int hashmap_get (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  if (!hashmap_fetch_value(L, data_idx, 2)) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}

static int hashmap_contains (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  if (is_collection(L, 2)) {
    lua_Integer i;
    lua_Integer count = collection_size(L, 2);
    for (i = 0; i < count; i++) {
      lua_rawgeti(L, 2, i);
      if (!hashmap_fetch_value(L, data_idx, -1)) {
        lua_pop(L, 2);
        lua_pushboolean(L, 0);
        return 1;
      }
      lua_pop(L, 2);
    }
    lua_pop(L, 1);
    lua_pushboolean(L, 1);
    return 1;
  }
  lua_pushboolean(L, hashmap_fetch_value(L, data_idx, 2));
  lua_pop(L, 1);
  return 1;
}

static int hashmap_remove_key (lua_State *L) {
  return hashmap_remove_key_internal(L, 1, 2, 1);
}

static int hashmap_remove_all (lua_State *L) {
  int self = 1;
  lua_Integer i;
  lua_Integer count = collection_size(L, 2);
  for (i = 0; i < count; i++) {
    lua_rawgeti(L, 2, i);
    hashmap_remove_key_internal(L, self, -1, 0);
    lua_pop(L, 1);
  }
  return 0;
}

static int hashmap_remove_if (lua_State *L) {
  int self = 1;
  int data_idx = lua_absindex(L, get_data_table(L, self));
  int keys_idx = lua_absindex(L, get_keys_table(L, self));
  lua_Integer size = get_int_field(L, self, "size", 0);
  lua_Integer i = 0;
  luaL_checktype(L, 2, LUA_TFUNCTION);
  while (i < size) {
    int base = lua_gettop(L);
    lua_rawgeti(L, keys_idx, i);
    {
      int key_idx = lua_gettop(L);
      lua_pushvalue(L, -1);
      lua_rawget(L, data_idx);
      lua_pushvalue(L, 2);
      lua_pushvalue(L, key_idx);
      lua_pushvalue(L, -3);
      lua_call(L, 2, 1);
      if (lua_toboolean(L, -1)) {
        lua_pop(L, 1);
        hashmap_remove_key_internal(L, self, key_idx, 0);
        size = get_int_field(L, self, "size", size);
        lua_settop(L, base);
      }
      else {
        lua_settop(L, base);
        i++;
      }
    }
  }
  lua_pop(L, 2);
  return 0;
}

static int hashmap_remove (lua_State *L) {
  if (is_collection(L, 2))
    return hashmap_remove_all(L);
  return hashmap_remove_key(L);
}

static int hashmap_clear (lua_State *L) {
  lua_newtable(L);
  lua_pushliteral(L, "__data");
  lua_insert(L, -2);
  lua_rawset(L, 1);
  lua_newtable(L);
  lua_pushliteral(L, "__keys");
  lua_insert(L, -2);
  lua_rawset(L, 1);
  set_size(L, 1, 0);
  return 0;
}

static int hashmap_is_empty (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_pushboolean(L, size == 0);
  return 1;
}

static int hashmap_iterator_next (lua_State *L) {
  lua_Integer i = lua_tointeger(L, lua_upvalueindex(2));
  lua_Integer size;
  int map_idx = lua_upvalueindex(1);
  int base = lua_gettop(L);
  i++;
  lua_pushinteger(L, i);
  lua_copy(L, -1, lua_upvalueindex(2));
  lua_pop(L, 1);
  lua_getfield(L, map_idx, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (i >= size) {
    push_none(L);
    return 1;
  }
  lua_pushliteral(L, "__keys");
  lua_rawget(L, map_idx);
  lua_rawgeti(L, -1, i);
  lua_pushliteral(L, "__data");
  lua_rawget(L, map_idx);
  lua_pushvalue(L, -2);
  lua_rawget(L, -2);
  push_tuple(L, -3, -1);
  push_some(L, -1);
  lua_remove(L, -2);
  lua_replace(L, base + 1);
  lua_settop(L, base + 1);
  return 1;
}

static int hashmap_iterator (lua_State *L) {
  lua_pushvalue(L, 1);
  lua_pushinteger(L, -1);
  lua_pushcclosure(L, hashmap_iterator_next, 2);
  return 1;
}

static int hashmap_keys (lua_State *L) {
  int data_idx = get_keys_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_newtable(L);
  {
    int result_idx = lua_gettop(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
      lua_rawseti(L, result_idx, i);
  }
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "__n");
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "size");
  }
  lua_remove(L, data_idx);
  return 1;
}

static int hashmap_values (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  int keys_idx = get_keys_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_newtable(L);
  {
    int result_idx = lua_gettop(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    lua_pushvalue(L, -1);
    lua_rawget(L, data_idx);
      lua_rawseti(L, result_idx, i);
    lua_pop(L, 1);
  }
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "__n");
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "size");
  }
  if (keys_idx > data_idx) {
    lua_remove(L, keys_idx);
    lua_remove(L, data_idx);
  }
  else {
    lua_remove(L, data_idx);
    lua_remove(L, keys_idx);
  }
  return 1;
}

static int hashmap_to_array (lua_State *L) {
  int data_idx = lua_absindex(L, get_data_table(L, 1));
  int keys_idx = lua_absindex(L, get_keys_table(L, 1));
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_newtable(L);
  {
    int result_idx = lua_gettop(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    lua_pushvalue(L, -1);
    lua_rawget(L, data_idx);
    push_tuple(L, -2, -1);
      lua_rawseti(L, result_idx, i);
    lua_pop(L, 2);
  }
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "__n");
  lua_pushinteger(L, size);
    lua_setfield(L, result_idx, "size");
  }
  if (keys_idx > data_idx) {
    lua_remove(L, keys_idx);
    lua_remove(L, data_idx);
  }
  else {
    lua_remove(L, data_idx);
    lua_remove(L, keys_idx);
  }
  return 1;
}

static int hashmap_clone (lua_State *L) {
  lua_Integer capacity = get_int_field(L, 1, "capacity", 16);
  lua_getglobal(L, "HashMap");
  lua_call(L, 0, 1);
  {
    int new_self = lua_gettop(L);
    int new_data = lua_absindex(L, get_data_table(L, new_self));
    int new_keys = lua_absindex(L, get_keys_table(L, new_self));
    hashmap_add_collection(L, new_self, new_data, new_keys, 1);
    lua_pushinteger(L, capacity);
    lua_pushliteral(L, "capacity");
    lua_insert(L, -2);
    lua_rawset(L, new_self);
    lua_remove(L, new_keys);
    lua_remove(L, new_data);
  }
  return 1;
}

static int hashmap_entry_index (lua_State *L) {
  const char *key = luaL_checkstring(L, 2);
  if (strcmp(key, "value") == 0) {
    int base = lua_gettop(L);
    int map_idx;
    int key_idx;
    int data_idx;
    lua_getfield(L, 1, "__map");
    lua_getfield(L, 1, "__key");
    map_idx = lua_absindex(L, -2);
    key_idx = lua_absindex(L, -1);
    data_idx = lua_absindex(L, get_data_table(L, map_idx));
    if (!hashmap_fetch_value(L, data_idx, key_idx)) {
      push_none(L);
    }
    else {
      push_some(L, -1);
      lua_remove(L, -2);
    }
    lua_replace(L, base + 1);
    lua_settop(L, base + 1);
    return 1;
  }
  lua_rawget(L, 1);
  return 1;
}

static int hashmap_entry_newindex (lua_State *L) {
  const char *key = luaL_checkstring(L, 2);
  if (strcmp(key, "value") == 0) {
    int map_idx;
    int key_idx;
    int data_idx;
    int keys_idx;
    lua_getfield(L, 1, "__map");
    lua_getfield(L, 1, "__key");
    map_idx = lua_absindex(L, -2);
    key_idx = lua_absindex(L, -1);
    data_idx = lua_absindex(L, get_data_table(L, map_idx));
    keys_idx = lua_absindex(L, get_keys_table(L, map_idx));
    if (lua_isnil(L, 3) || is_none(L, 3)) {
      hashmap_remove_key_internal(L, map_idx, key_idx, 0);
    }
    else if (cangjie_has_tag(L, 3, "Some")) {
      lua_rawgeti(L, 3, 1);
      hashmap_add_entry(L, map_idx, data_idx, keys_idx, key_idx, -1);
      lua_pop(L, 1);
    }
    else {
      hashmap_add_entry(L, map_idx, data_idx, keys_idx, key_idx, 3);
    }
    lua_remove(L, keys_idx);
    lua_remove(L, data_idx);
    lua_pop(L, 2);
    return 0;
  }
  lua_rawset(L, 1);
  return 0;
}

static int hashmap_entry_view (lua_State *L) {
  lua_newtable(L);
  lua_pushvalue(L, 1);
  lua_setfield(L, -2, "__map");
  lua_pushvalue(L, 2);
  lua_setfield(L, -2, "__key");
  lua_pushvalue(L, 2);
  lua_setfield(L, -2, "key");
  lua_newtable(L);
  lua_pushcfunction(L, hashmap_entry_index);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, hashmap_entry_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_setmetatable(L, -2);
  return 1;
}

static int hashmap_reserve (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  if (additional <= 0)
    return 0;
  ensure_capacity(L, 1, size + additional);
  return 0;
}

static int hashmap_index_operator (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  if (!hashmap_fetch_value(L, data_idx, 2)) {
    lua_pop(L, 1);
    return luaL_error(L, "key not found");
  }
  lua_remove(L, data_idx);
  return 1;
}

static int hashmap_newindex (lua_State *L) {
  int self = 1;
  int data_idx = get_data_table(L, self);
  int keys_idx = get_keys_table(L, self);
  if (lua_isnil(L, 3) || is_none(L, 3)) {
    lua_pop(L, 2);
    hashmap_remove_key_internal(L, self, 2, 0);
    return 0;
  }
  if (cangjie_has_tag(L, 3, "Some")) {
    lua_rawgeti(L, 3, 1);
    hashmap_add_entry(L, self, data_idx, keys_idx, 2, -1);
    lua_pop(L, 1);
  }
  else {
    hashmap_add_entry(L, self, data_idx, keys_idx, 2, 3);
  }
  lua_pop(L, 2);
  return 0;
}

static int hashmap_eq (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer other_size = get_int_field(L, 2, "size", -1);
  int data_idx;
  int keys_idx;
  lua_Integer i;
  if (other_size < 0 || size != other_size) {
    lua_pushboolean(L, 0);
    return 1;
  }
  data_idx = lua_absindex(L, get_data_table(L, 1));
  keys_idx = lua_absindex(L, get_keys_table(L, 1));
  lua_pushliteral(L, "__data");
  lua_rawget(L, 2);
  {
    int other_data = lua_absindex(L, -1);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    lua_pushvalue(L, -1);
    lua_rawget(L, data_idx);
    lua_pushvalue(L, -2);
      lua_rawget(L, other_data);
    if (!lua_rawequal(L, -1, -2)) {
      lua_pop(L, 3);
      lua_pop(L, 1);
      lua_pop(L, 2);
      lua_pushboolean(L, 0);
      return 1;
    }
      lua_pop(L, 3);
  }
    lua_pop(L, 1);
  }
  lua_pop(L, 2);
  lua_pushboolean(L, 1);
  return 1;
}

static int hashmap_tostring (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  int keys_idx = get_keys_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  for (i = 0; i < size; i++) {
    if (i > 0)
      luaL_addstring(&b, ", ");
    lua_rawgeti(L, keys_idx, i);
    lua_pushvalue(L, -1);
    lua_rawget(L, data_idx);
    luaL_addchar(&b, '(');
    luaL_addvalue(&b);
    luaL_addstring(&b, ", ");
    luaL_addvalue(&b);
    luaL_addchar(&b, ')');
  }
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  if (keys_idx > data_idx) {
    lua_remove(L, keys_idx);
    lua_remove(L, data_idx);
  }
  else {
    lua_remove(L, data_idx);
    lua_remove(L, keys_idx);
  }
  return 1;
}

static const luaL_Reg hashmap_methods[] = {
  {"init", hashmap_init},
  {"add", hashmap_add},
  {"replace", hashmap_replace},
  {"get", hashmap_get},
  {"contains", hashmap_contains},
  {"remove", hashmap_remove},
  {"removeIf", hashmap_remove_if},
  {"clear", hashmap_clear},
  {"clone", hashmap_clone},
  {"isEmpty", hashmap_is_empty},
  {"iterator", hashmap_iterator},
  {"keys", hashmap_keys},
  {"values", hashmap_values},
  {"entryView", hashmap_entry_view},
  {"reserve", hashmap_reserve},
  {"toArray", hashmap_to_array},
  {"toString", hashmap_tostring},
  {"__newindex", hashmap_newindex},
  {"__index", hashmap_index_operator},
  {"__eq", hashmap_eq},
  {"__tostring", hashmap_tostring},
  {NULL, NULL}
};

int luaB_hashmap_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, hashmap_methods, 0);
  cangjie_register_class_global(L, "HashMap");
  return 0;
}
