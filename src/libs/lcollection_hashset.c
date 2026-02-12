/*
** HashSet implementation for Cangjie collection package.
*/

#define lcollection_hashset_c
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
  lua_setfield(L, self, "size");
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
    lua_setfield(L, self, "capacity");
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


static int hashset_has_key (lua_State *L, int data_idx, int key_idx) {
  data_idx = lua_absindex(L, data_idx);
  key_idx = lua_absindex(L, key_idx);
  lua_pushvalue(L, key_idx);
  lua_rawget(L, data_idx);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    return 0;
  }
  lua_pop(L, 1);
  return 1;
}


static int collection_keys_table (lua_State *L, int idx, lua_Integer *size) {
  idx = lua_absindex(L, idx);
  lua_pushliteral(L, "__keys");
  lua_rawget(L, idx);
  if (lua_istable(L, -1)) {
    *size = get_int_field(L, idx, "size", 0);
    return lua_gettop(L);
  }
  lua_pop(L, 1);
  *size = collection_size(L, idx);
  return 0;
}


static int hashset_add_value (lua_State *L, int self, int data_idx,
                              int keys_idx, int key_idx) {
  lua_Integer size = get_int_field(L, self, "size", 0);
  if (hashset_has_key(L, data_idx, key_idx))
    return 0;
  ensure_capacity(L, self, size + 1);
  lua_pushvalue(L, key_idx);
  lua_rawseti(L, keys_idx, size);
  lua_pushvalue(L, key_idx);
  lua_pushboolean(L, 1);
  lua_rawset(L, data_idx);
  set_size(L, self, size + 1);
  return 1;
}


static int hashset_remove_key (lua_State *L, int self, int key_idx) {
  key_idx = lua_absindex(L, key_idx);
  {
    int data_idx = get_data_table(L, self);
    int keys_idx = get_keys_table(L, self);
  lua_Integer size = get_int_field(L, self, "size", 0);
  int key_index;
  if (!hashset_has_key(L, data_idx, key_idx)) {
    lua_pop(L, 2);
    return 0;
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
  lua_pop(L, 2);
  }
  return 1;
}


static int hashset_call_contains (lua_State *L, int set_idx, int key_idx) {
  int result = 0;
  set_idx = lua_absindex(L, set_idx);
  key_idx = lua_absindex(L, key_idx);
  lua_getfield(L, set_idx, "__class");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "contains");
    if (lua_isfunction(L, -1)) {
      lua_pushvalue(L, set_idx);
      lua_pushvalue(L, key_idx);
      lua_call(L, 2, 1);
      result = lua_toboolean(L, -1);
      lua_pop(L, 2);
      return result;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_getfield(L, set_idx, "contains");
  if (lua_isfunction(L, -1)) {
    lua_pushvalue(L, key_idx);
    lua_call(L, 1, 1);
    result = lua_toboolean(L, -1);
    lua_pop(L, 1);
  }
  else {
    lua_pop(L, 1);
  }
  return result;
}


static int hashset_init (lua_State *L) {
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
    else if (is_collection(L, 2)) {
      lua_Integer i;
      lua_Integer count;
      int src_keys = collection_keys_table(L, 2, &count);
      for (i = 0; i < count; i++) {
        if (src_keys != 0)
          lua_rawgeti(L, src_keys, i);
        else
          lua_rawgeti(L, 2, i);
        size += hashset_add_value(L, self, data_idx, keys_idx, -1);
        lua_pop(L, 1);
      }
      if (src_keys != 0)
        lua_pop(L, 1);
      capacity = size > 16 ? size : 16;
    }
  }
  else if (nargs == 2 && lua_isinteger(L, 2) && lua_isfunction(L, 3)) {
    lua_Integer i;
    size = lua_tointeger(L, 2);
    luaL_argcheck(L, size >= 0, 2, "size must be non-negative");
    for (i = 0; i < size; i++) {
      lua_pushvalue(L, 3);
      lua_pushinteger(L, i);
      lua_call(L, 1, 1);
      hashset_add_value(L, self, data_idx, keys_idx, -1);
      lua_pop(L, 1);
    }
    capacity = size > 16 ? size : 16;
  }
  lua_pushinteger(L, capacity);
  lua_setfield(L, self, "capacity");
  set_size(L, self, size);
  lua_pop(L, 2);
  return 0;
}


static int hashset_add (lua_State *L) {
  int self = 1;
  int data_idx = get_data_table(L, self);
  int keys_idx = get_keys_table(L, self);
  if (is_collection(L, 2)) {
    lua_Integer i;
    lua_Integer count;
    int src_keys = collection_keys_table(L, 2, &count);
    for (i = 0; i < count; i++) {
      if (src_keys != 0)
        lua_rawgeti(L, src_keys, i);
      else
        lua_rawgeti(L, 2, i);
      hashset_add_value(L, self, data_idx, keys_idx, -1);
      lua_pop(L, 1);
    }
    if (src_keys != 0)
      lua_pop(L, 1);
    lua_pop(L, 2);
    return 0;
  }
  lua_pushboolean(L, hashset_add_value(L, self, data_idx, keys_idx, 2));
  lua_remove(L, keys_idx);
  lua_remove(L, data_idx);
  return 1;
}


static int hashset_contains (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  if (is_collection(L, 2)) {
    lua_Integer i;
    lua_Integer count;
    int src_keys = collection_keys_table(L, 2, &count);
    for (i = 0; i < count; i++) {
      if (src_keys != 0)
        lua_rawgeti(L, src_keys, i);
      else
        lua_rawgeti(L, 2, i);
      if (!hashset_has_key(L, data_idx, -1)) {
        lua_pop(L, 2);
        if (src_keys != 0)
          lua_pop(L, 1);
        lua_pushboolean(L, 0);
        return 1;
      }
      lua_pop(L, 1);
    }
    if (src_keys != 0)
      lua_pop(L, 1);
    lua_pop(L, 1);
    lua_pushboolean(L, 1);
    return 1;
  }
  lua_pushboolean(L, hashset_has_key(L, data_idx, 2));
  lua_remove(L, data_idx);
  return 1;
}


static int hashset_remove (lua_State *L) {
  if (is_collection(L, 2)) {
    lua_Integer i;
    lua_Integer count;
    int src_keys = collection_keys_table(L, 2, &count);
    for (i = 0; i < count; i++) {
      if (src_keys != 0)
        lua_rawgeti(L, src_keys, i);
      else
        lua_rawgeti(L, 2, i);
      hashset_remove_key(L, 1, -1);
      lua_pop(L, 1);
    }
    if (src_keys != 0)
      lua_pop(L, 1);
    return 0;
  }
  lua_pushboolean(L, hashset_remove_key(L, 1, 2));
  return 1;
}


static int hashset_remove_if (lua_State *L) {
  int self = 1;
  int keys_idx = get_keys_table(L, self);
  lua_Integer size = get_int_field(L, self, "size", 0);
  lua_Integer i = 0;
  luaL_checktype(L, 2, LUA_TFUNCTION);
  while (i < size) {
    lua_rawgeti(L, keys_idx, i);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 1);
    if (lua_toboolean(L, -1)) {
      lua_pop(L, 1);
      hashset_remove_key(L, self, -1);
      size = get_int_field(L, self, "size", size);
      lua_pop(L, 1);
    }
    else {
      lua_pop(L, 2);
      i++;
    }
  }
  lua_pop(L, 1);
  return 0;
}


static int hashset_clear (lua_State *L) {
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


static int hashset_clone (lua_State *L) {
  int keys_idx = lua_absindex(L, get_keys_table(L, 1));
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer capacity = get_int_field(L, 1, "capacity", 16);
  lua_Integer i;
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int new_self = lua_gettop(L);
    int new_data;
    int new_keys;
    lua_newtable(L);
    new_data = lua_gettop(L);
    lua_pushliteral(L, "__data");
    lua_pushvalue(L, new_data);
    lua_rawset(L, new_self);
    lua_newtable(L);
    new_keys = lua_gettop(L);
    lua_pushliteral(L, "__keys");
    lua_pushvalue(L, new_keys);
    lua_rawset(L, new_self);
    for (i = 0; i < size; i++) {
      lua_rawgeti(L, keys_idx, i);
      lua_pushvalue(L, -1);
      lua_rawseti(L, new_keys, i);
      lua_pushboolean(L, 1);
      lua_rawset(L, new_data);  /* store key in data table */
    }
    lua_pushinteger(L, capacity);
    lua_setfield(L, new_self, "capacity");
    set_size(L, new_self, size);
    lua_pop(L, 2);
  }
  lua_remove(L, keys_idx);
  lua_remove(L, 1);
  return 1;
}


static int hashset_is_empty (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_pushboolean(L, size == 0);
  return 1;
}


static int hashset_iterator_next (lua_State *L) {
  lua_Integer i = lua_tointeger(L, lua_upvalueindex(2));
  lua_Integer size;
  int set_idx = lua_upvalueindex(1);
  i++;
  lua_pushinteger(L, i);
  lua_copy(L, -1, lua_upvalueindex(2));
  lua_pop(L, 1);
  lua_getfield(L, set_idx, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (i >= size) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, set_idx, "__keys");
  lua_rawgeti(L, -1, i);
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}


static int hashset_iterator (lua_State *L) {
  lua_pushvalue(L, 1);
  lua_pushinteger(L, -1);
  lua_pushcclosure(L, hashset_iterator_next, 2);
  return 1;
}


static int hashset_retain (lua_State *L) {
  int self = 1;
  int keys_idx = get_keys_table(L, self);
  lua_Integer size = get_int_field(L, self, "size", 0);
  lua_Integer i;
  lua_Integer new_size = 0;
  int new_data;
  int new_keys;
  lua_newtable(L);
  new_data = lua_gettop(L);
  lua_newtable(L);
  new_keys = lua_gettop(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    if (hashset_call_contains(L, 2, -1)) {
      lua_pushvalue(L, -1);
      lua_rawseti(L, new_keys, new_size);
      lua_pushvalue(L, -1);
      lua_pushboolean(L, 1);
      lua_rawset(L, new_data);
      new_size++;
    }
    lua_pop(L, 1);
  }
  lua_pushvalue(L, new_data);
  lua_setfield(L, self, "__data");
  lua_pushvalue(L, new_keys);
  lua_setfield(L, self, "__keys");
  set_size(L, self, new_size);
  lua_pop(L, 3);
  return 0;
}


static int hashset_subset_of (lua_State *L) {
  int keys_idx = get_keys_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    if (!hashset_call_contains(L, 2, -1)) {
      lua_pop(L, 2);
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_pushboolean(L, 1);
  return 1;
}


static int hashset_to_array (lua_State *L) {
  int keys_idx = get_keys_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_newtable(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    lua_rawseti(L, -2, i);
  }
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  lua_remove(L, keys_idx);
  return 1;
}


static int hashset_reserve (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  if (additional <= 0)
    return 0;
  ensure_capacity(L, 1, size + additional);
  return 0;
}


static int hashset_op_intersect (lua_State *L) {
  int keys_idx = get_keys_table(L, 1);
  int other_data = get_data_table(L, 2);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int res_idx = lua_gettop(L);
    int res_data = get_data_table(L, res_idx);
    int res_keys = get_keys_table(L, res_idx);
    for (i = 0; i < size; i++) {
      lua_rawgeti(L, keys_idx, i);
      if (hashset_has_key(L, other_data, -1)) {
        hashset_add_value(L, res_idx, res_data, res_keys, -1);
      }
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
  }
  if (other_data > keys_idx) {
    lua_remove(L, other_data);
    lua_remove(L, keys_idx);
  }
  else {
    lua_remove(L, keys_idx);
    lua_remove(L, other_data);
  }
  return 1;
}


static int hashset_op_union (lua_State *L) {
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int res_idx = lua_gettop(L);
    int res_data = get_data_table(L, res_idx);
    int res_keys = get_keys_table(L, res_idx);
    int left_keys = get_keys_table(L, 1);
    int right_keys = get_keys_table(L, 2);
    lua_Integer left_size = get_int_field(L, 1, "size", 0);
    lua_Integer right_size = get_int_field(L, 2, "size", 0);
    lua_Integer i;
    for (i = 0; i < left_size; i++) {
      lua_rawgeti(L, left_keys, i);
      hashset_add_value(L, res_idx, res_data, res_keys, -1);
      lua_pop(L, 1);
    }
    for (i = 0; i < right_size; i++) {
      lua_rawgeti(L, right_keys, i);
      hashset_add_value(L, res_idx, res_data, res_keys, -1);
      lua_pop(L, 1);
    }
    lua_pop(L, 4);
  }
  return 1;
}


static int hashset_op_diff (lua_State *L) {
  int keys_idx = get_keys_table(L, 1);
  int other_data = get_data_table(L, 2);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_getglobal(L, "HashSet");
  lua_call(L, 0, 1);
  {
    int res_idx = lua_gettop(L);
    int res_data = get_data_table(L, res_idx);
    int res_keys = get_keys_table(L, res_idx);
    for (i = 0; i < size; i++) {
      lua_rawgeti(L, keys_idx, i);
      if (!hashset_has_key(L, other_data, -1)) {
        hashset_add_value(L, res_idx, res_data, res_keys, -1);
      }
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
  }
  if (other_data > keys_idx) {
    lua_remove(L, other_data);
    lua_remove(L, keys_idx);
  }
  else {
    lua_remove(L, keys_idx);
    lua_remove(L, other_data);
  }
  return 1;
}


static int hashset_eq (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer other_size = get_int_field(L, 2, "size", -1);
  int keys_idx;
  lua_Integer i;
  if (other_size < 0 || size != other_size) {
    lua_pushboolean(L, 0);
    return 1;
  }
  keys_idx = get_keys_table(L, 1);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, keys_idx, i);
    if (!hashset_call_contains(L, 2, -1)) {
      lua_pop(L, 2);
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_pushboolean(L, 1);
  return 1;
}


static int hashset_tostring (lua_State *L) {
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
    luaL_addvalue(&b);
  }
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  lua_remove(L, keys_idx);
  return 1;
}


static const luaL_Reg hashset_methods[] = {
  {"init", hashset_init},
  {"add", hashset_add},
  {"contains", hashset_contains},
  {"remove", hashset_remove},
  {"removeIf", hashset_remove_if},
  {"clear", hashset_clear},
  {"clone", hashset_clone},
  {"isEmpty", hashset_is_empty},
  {"iterator", hashset_iterator},
  {"retain", hashset_retain},
  {"subsetOf", hashset_subset_of},
  {"toArray", hashset_to_array},
  {"reserve", hashset_reserve},
  {"toString", hashset_tostring},
  /* Metamethods overload bitwise operators for set ops: &/|/-. */
  {"__band", hashset_op_intersect},
  {"__bor", hashset_op_union},
  {"__sub", hashset_op_diff},
  {"__eq", hashset_eq},
  {"__tostring", hashset_tostring},
  {NULL, NULL}
};


int luaB_hashset_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, hashset_methods, 0);
  cangjie_register_class_global(L, "HashSet");
  return 0;
}
