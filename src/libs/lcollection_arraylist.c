/*
** ArrayList implementation for Cangjie collection package.
** Backed by Lua tables for dynamic storage.
*/

#define lcollection_arraylist_c
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
  lua_getfield(L, self, "__data");
  if (lua_istable(L, -1))
    return lua_gettop(L);
  lua_pop(L, 1);
  lua_newtable(L);
  lua_setfield(L, self, "__data");
  lua_getfield(L, self, "__data");
  return lua_gettop(L);
}

static int get_collection_data (lua_State *L, int idx) {
  idx = lua_absindex(L, idx);
  lua_getfield(L, idx, "__data");
  if (lua_istable(L, -1))
    return lua_gettop(L);
  lua_pop(L, 1);
  lua_pushvalue(L, idx);
  return lua_gettop(L);
}

static void update_first_last (lua_State *L, int self, int data_idx,
                               lua_Integer size) {
  self = lua_absindex(L, self);
  data_idx = lua_absindex(L, data_idx);
  if (size <= 0) {
    push_none(L);
    lua_setfield(L, self, "first");
    push_none(L);
    lua_setfield(L, self, "last");
    return;
  }
  lua_rawgeti(L, data_idx, 0);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    push_none(L);
  }
  else {
    push_some(L, -1);
    lua_remove(L, -2);
  }
  lua_setfield(L, self, "first");

  lua_rawgeti(L, data_idx, size - 1);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    push_none(L);
  }
  else {
    push_some(L, -1);
    lua_remove(L, -2);
  }
  lua_setfield(L, self, "last");
}

static void set_size (lua_State *L, int self, int data_idx, lua_Integer size) {
  self = lua_absindex(L, self);
  lua_pushinteger(L, size);
  lua_setfield(L, self, "size");
  lua_pushinteger(L, size);
  lua_setfield(L, self, "__n");
  update_first_last(L, self, data_idx, size);
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

static void arraylist_append_value (lua_State *L, int self, int data_idx,
                                    int value_idx) {
  lua_Integer size = get_int_field(L, self, "size", 0);
  ensure_capacity(L, self, size + 1);
  lua_pushvalue(L, value_idx);
  lua_rawseti(L, data_idx, size);
  set_size(L, self, data_idx, size + 1);
}

static int arraylist_init (lua_State *L) {
  int self = 1;
  int nargs = lua_gettop(L) - 1;
  int data_idx = get_data_table(L, self);
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
      int src_idx = get_collection_data(L, 2);
      size = collection_size(L, 2);
      for (i = 0; i < size; i++) {
        lua_rawgeti(L, src_idx, i);
        lua_rawseti(L, data_idx, i);
      }
      capacity = size > 16 ? size : 16;
      lua_pop(L, 1);
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
        lua_rawseti(L, data_idx, i);
      }
      capacity = size > 16 ? size : 16;
    }
  }
  lua_pushinteger(L, capacity);
  lua_setfield(L, self, "capacity");
  set_size(L, self, data_idx, size);
  lua_pop(L, 1);
  return 0;
}

static int arraylist_is_empty (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_pushboolean(L, size == 0);
  return 1;
}

static int arraylist_add (lua_State *L) {
  int nargs = lua_gettop(L) - 1;
  int self = 1;
  int data_idx = get_data_table(L, self);
  if (nargs == 1) {
    if (is_collection(L, 2)) {
      lua_Integer i;
      lua_Integer count = collection_size(L, 2);
      int src_idx = get_collection_data(L, 2);
      for (i = 0; i < count; i++) {
        lua_rawgeti(L, src_idx, i);
        arraylist_append_value(L, self, data_idx, lua_gettop(L));
        lua_pop(L, 1);
      }
      lua_pop(L, 1);
    }
    else {
      arraylist_append_value(L, self, data_idx, 2);
    }
    lua_pop(L, 1);
    return 0;
  }
  if (nargs == 2) {
    lua_Integer at = luaL_checkinteger(L, 3);
    lua_Integer size = get_int_field(L, self, "size", 0);
    luaL_argcheck(L, at >= 0 && at <= size, 3, "index out of range");
    if (is_collection(L, 2)) {
      lua_Integer i;
      lua_Integer count = collection_size(L, 2);
      int src_idx = get_collection_data(L, 2);
      ensure_capacity(L, self, size + count);
      for (i = size - 1; i >= at; i--) {
        lua_rawgeti(L, data_idx, i);
        lua_rawseti(L, data_idx, i + count);
      }
      for (i = 0; i < count; i++) {
        lua_rawgeti(L, src_idx, i);
        lua_rawseti(L, data_idx, at + i);
      }
      set_size(L, self, data_idx, size + count);
      lua_pop(L, 1);
    }
    else {
      ensure_capacity(L, self, size + 1);
      {
        lua_Integer i;
        for (i = size - 1; i >= at; i--) {
          lua_rawgeti(L, data_idx, i);
          lua_rawseti(L, data_idx, i + 1);
        }
      }
      lua_pushvalue(L, 2);
      lua_rawseti(L, data_idx, at);
      set_size(L, self, data_idx, size + 1);
    }
    lua_pop(L, 1);
    return 0;
  }
  return luaL_error(L, "ArrayList.add expects 1 or 2 arguments");
}

static int arraylist_get (lua_State *L) {
  int self = 1;
  lua_Integer idx = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  if (idx < 0 || idx >= size) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  lua_rawgeti(L, data_idx, idx);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 2);
    push_none(L);
    return 1;
  }
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}

static int arraylist_get_raw (lua_State *L) {
  int self = 1;
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  lua_Integer i;
  lua_newtable(L);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
    lua_rawseti(L, -2, i);
  }
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  lua_remove(L, data_idx);
  return 1;
}

static int arraylist_remove_at (lua_State *L) {
  int self = 1;
  lua_Integer at = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  lua_Integer i;
  luaL_argcheck(L, at >= 0 && at < size, 2, "index out of range");
  lua_rawgeti(L, data_idx, at);
  for (i = at + 1; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
    lua_rawseti(L, data_idx, i - 1);
  }
  lua_pushnil(L);
  lua_rawseti(L, data_idx, size - 1);
  set_size(L, self, data_idx, size - 1);
  lua_remove(L, data_idx);
  return 1;
}

static int parse_range (lua_State *L, int idx, lua_Integer size,
                        lua_Integer *start, lua_Integer *end) {
  lua_Integer step;
  int has_end;
  int is_closed;
  idx = lua_absindex(L, idx);
  *start = get_int_field(L, idx, "start", 0);
  *end = get_int_field(L, idx, "end", size - 1);
  step = get_int_field(L, idx, "step", 1);
  has_end = get_int_field(L, idx, "hasEnd", 1) != 0;
  is_closed = get_int_field(L, idx, "isClosed", 0) != 0;
  if (step != 1)
    return luaL_error(L, "range step must be 1");
  if (!has_end)
    *end = size - 1;
  else if (!is_closed)
    *end = *end - 1;
  if (*start < 0 || *end >= size)
    return luaL_error(L, "range out of bounds");
  if (*end < *start)
    *end = *start - 1;
  return 0;
}

static int arraylist_remove_range (lua_State *L) {
  int self = 1;
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  lua_Integer start, end, i, count;
  parse_range(L, 2, size, &start, &end);
  if (end < start) {
    lua_pop(L, 1);
    return 0;
  }
  count = end - start + 1;
  for (i = end + 1; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
    lua_rawseti(L, data_idx, i - count);
  }
  for (i = size - count; i < size; i++) {
    lua_pushnil(L);
    lua_rawseti(L, data_idx, i);
  }
  set_size(L, self, data_idx, size - count);
  lua_pop(L, 1);
  return 0;
}

static int arraylist_remove (lua_State *L) {
  if (lua_istable(L, 2))
    return arraylist_remove_range(L);
  return arraylist_remove_at(L);
}

static int arraylist_remove_if (lua_State *L) {
  int self = 1;
  int data_idx = get_data_table(L, self);
  lua_Integer i = 0;
  lua_Integer size = get_int_field(L, self, "size", 0);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  while (i < size) {
    lua_pushvalue(L, 2);
    lua_rawgeti(L, data_idx, i);
    lua_call(L, 1, 1);
    if (lua_toboolean(L, -1)) {
      lua_pop(L, 1);
      {
        lua_Integer j;
        for (j = i + 1; j < size; j++) {
          lua_rawgeti(L, data_idx, j);
          lua_rawseti(L, data_idx, j - 1);
        }
      }
      lua_pushnil(L);
      lua_rawseti(L, data_idx, size - 1);
      size--;
      set_size(L, self, data_idx, size);
    }
    else {
      lua_pop(L, 2);
      i++;
    }
  }
  lua_pop(L, 1);
  return 0;
}

static int arraylist_clear (lua_State *L) {
  int self = 1;
  lua_newtable(L);
  lua_setfield(L, self, "__data");
  {
    int data_idx = get_data_table(L, self);
    set_size(L, self, data_idx, 0);
    lua_pop(L, 1);
  }
  return 0;
}

static int arraylist_contains (lua_State *L) {
  int self = 1;
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  lua_Integer i;
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
    if (lua_rawequal(L, -1, 2)) {
      lua_pop(L, 2);
      lua_pushboolean(L, 1);
      return 1;
    }
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_pushboolean(L, 0);
  return 1;
}

static int arraylist_clone (lua_State *L) {
  int self = 1;
  lua_Integer size = get_int_field(L, self, "size", 0);
  lua_Integer capacity = get_int_field(L, self, "capacity", 16);
  int data_idx = get_data_table(L, self);
  lua_Integer i;
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  {
    int new_self = lua_gettop(L);
    int new_data = get_data_table(L, new_self);
    for (i = 0; i < size; i++) {
      lua_rawgeti(L, data_idx, i);
      lua_rawseti(L, new_data, i);
    }
    lua_pushinteger(L, capacity);
    lua_setfield(L, new_self, "capacity");
    set_size(L, new_self, new_data, size);
    lua_pop(L, 1);
  }
  lua_remove(L, data_idx);
  return 1;
}

static int arraylist_reserve (lua_State *L) {
  int self = 1;
  lua_Integer additional = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, self, "size", 0);
  if (additional <= 0)
    return 0;
  ensure_capacity(L, self, size + additional);
  return 0;
}

static int arraylist_reverse (lua_State *L) {
  int self = 1;
  int data_idx = get_data_table(L, self);
  lua_Integer size = get_int_field(L, self, "size", 0);
  lua_Integer i;
  for (i = 0; i < size / 2; i++) {
    lua_rawgeti(L, data_idx, i);
    lua_rawgeti(L, data_idx, size - 1 - i);
    lua_rawseti(L, data_idx, i);
    lua_rawseti(L, data_idx, size - 1 - i);
  }
  update_first_last(L, self, data_idx, size);
  lua_pop(L, 1);
  return 0;
}

static int arraylist_slice (lua_State *L) {
  int self = 1;
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  lua_Integer start, end, i, count;
  parse_range(L, 2, size, &start, &end);
  if (end < start)
    count = 0;
  else
    count = end - start + 1;
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  {
    int new_self = lua_gettop(L);
    int new_data = get_data_table(L, new_self);
    for (i = 0; i < count; i++) {
      lua_rawgeti(L, data_idx, start + i);
      lua_rawseti(L, new_data, i);
    }
    lua_pushinteger(L, count > 16 ? count : 16);
    lua_setfield(L, new_self, "capacity");
    set_size(L, new_self, new_data, count);
    lua_pop(L, 1);
  }
  lua_remove(L, data_idx);
  return 1;
}

static int arraylist_to_array (lua_State *L) {
  return arraylist_get_raw(L);
}

static int arraylist_iter_next (lua_State *L) {
  lua_Integer i = lua_tointeger(L, lua_upvalueindex(2));
  lua_Integer size;
  int data_idx = lua_upvalueindex(1);
  i++;
  lua_pushinteger(L, i);
  lua_copy(L, -1, lua_upvalueindex(2));
  lua_pop(L, 1);
  lua_getfield(L, data_idx, "size");
  size = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (i >= size) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, data_idx, "__data");
  lua_rawgeti(L, -1, i);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 2);
    push_none(L);
    return 1;
  }
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}

static int arraylist_iterator (lua_State *L) {
  lua_pushvalue(L, 1);
  lua_pushinteger(L, -1);
  lua_pushcclosure(L, arraylist_iter_next, 2);
  return 1;
}

static int arraylist_newindex (lua_State *L) {
  int self = 1;
  if (lua_type(L, 2) == LUA_TINT64 || lua_type(L, 2) == LUA_TFLOAT64) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer size = get_int_field(L, self, "size", 0);
    int data_idx = get_data_table(L, self);
    luaL_argcheck(L, idx >= 0 && idx < size, 2, "index out of range");
    lua_pushvalue(L, 3);
    lua_rawseti(L, data_idx, idx);
    update_first_last(L, self, data_idx, size);
    lua_pop(L, 1);
    return 0;
  }
  lua_rawset(L, 1);
  return 0;
}

static int arraylist_index_operator (lua_State *L) {
  int self = 1;
  lua_Integer idx = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, self, "size", 0);
  int data_idx = get_data_table(L, self);
  if (idx < 0 || idx >= size) {
    lua_pop(L, 1);
    return luaL_error(L, "index out of range");
  }
  lua_rawgeti(L, data_idx, idx);
  lua_remove(L, data_idx);
  return 1;
}

static int arraylist_eq (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer other_size = get_int_field(L, 2, "size", -1);
  lua_Integer i;
  int data_idx;
  int other_data;
  if (other_size < 0 || size != other_size) {
    lua_pushboolean(L, 0);
    return 1;
  }
  data_idx = get_data_table(L, 1);
  other_data = get_data_table(L, 2);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, data_idx, i);
    lua_rawgeti(L, other_data, i);
    if (!lua_rawequal(L, -1, -2)) {
      lua_pop(L, 4);
      lua_pushboolean(L, 0);
      return 1;
    }
    lua_pop(L, 2);
  }
  lua_pop(L, 2);
  lua_pushboolean(L, 1);
  return 1;
}

static int arraylist_tostring (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  int data_idx = get_data_table(L, 1);
  lua_Integer i;
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  for (i = 0; i < size; i++) {
    if (i > 0)
      luaL_addstring(&b, ", ");
    lua_rawgeti(L, data_idx, i);
    luaL_addvalue(&b);
  }
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  lua_remove(L, data_idx);
  return 1;
}

static int ordering_sign (lua_State *L, int idx) {
  idx = lua_absindex(L, idx);
  if (lua_isinteger(L, idx)) {
    lua_Integer v = lua_tointeger(L, idx);
    return (v > 0) - (v < 0);
  }
  if (lua_isnumber(L, idx)) {
    lua_Number v = lua_tonumber(L, idx);
    return (v > 0) - (v < 0);
  }
  if (lua_isstring(L, idx)) {
    const char *s = lua_tostring(L, idx);
    if (strcmp(s, "LT") == 0) return -1;
    if (strcmp(s, "GT") == 0) return 1;
    return 0;
  }
  if (lua_istable(L, idx)) {
    lua_getfield(L, idx, "__tag");
    if (lua_isstring(L, -1)) {
      const char *s = lua_tostring(L, -1);
      lua_pop(L, 1);
      if (strcmp(s, "LT") == 0) return -1;
      if (strcmp(s, "GT") == 0) return 1;
      return 0;
    }
    lua_pop(L, 1);
  }
  return 0;
}

static int arraylist_sort_compare (lua_State *L) {
  int stable = lua_toboolean(L, lua_upvalueindex(2));
  if (stable) {
    lua_getfield(L, 1, "value");
    lua_getfield(L, 2, "value");
  }
  if (stable) {
    int aidx = lua_gettop(L) - 1;
    int bidx = lua_gettop(L);
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_pushvalue(L, aidx);
    lua_pushvalue(L, bidx);
    lua_call(L, 2, 1);
    {
      int cmp = ordering_sign(L, -1);
      lua_pop(L, 1);
      lua_pop(L, 2);
      if (cmp == 0) {
        lua_getfield(L, 1, "index");
        lua_getfield(L, 2, "index");
        lua_pushboolean(L, lua_tointeger(L, -2) < lua_tointeger(L, -1));
        return 1;
      }
      lua_pushboolean(L, cmp < 0);
      return 1;
    }
  }
  else {
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 1);
    {
      int cmp = ordering_sign(L, -1);
      lua_pop(L, 1);
      lua_pushboolean(L, cmp < 0);
    }
    return 1;
  }
}

static int arraylist_sortby (lua_State *L) {
  int stable = 0;
  int comp_idx = 2;
  int nargs = lua_gettop(L);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  int data_idx = get_data_table(L, 1);
  lua_Integer i;
  if (nargs == 3) {
    stable = lua_toboolean(L, 2);
    comp_idx = 3;
  }
  luaL_checktype(L, comp_idx, LUA_TFUNCTION);
  lua_newtable(L);
  for (i = 0; i < size; i++) {
    if (stable) {
      lua_newtable(L);
      lua_rawgeti(L, data_idx, i);
      lua_setfield(L, -2, "value");
      lua_pushinteger(L, i);
      lua_setfield(L, -2, "index");
      lua_rawseti(L, -2, i + 1);
    }
    else {
      lua_rawgeti(L, data_idx, i);
      lua_rawseti(L, -2, i + 1);
    }
  }
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "sort");
  lua_remove(L, -2);
  lua_pushvalue(L, -2);
  lua_pushvalue(L, comp_idx);
  lua_pushboolean(L, stable);
  lua_pushcclosure(L, arraylist_sort_compare, 2);
  lua_call(L, 2, 0);
  for (i = 0; i < size; i++) {
    lua_rawgeti(L, -1, i + 1);
    if (stable) {
      lua_getfield(L, -1, "value");
      lua_rawseti(L, data_idx, i);
      lua_pop(L, 1);
    }
    else {
      lua_rawseti(L, data_idx, i);
    }
  }
  update_first_last(L, 1, data_idx, size);
  lua_pop(L, 2);
  return 0;
}

static const luaL_Reg arraylist_methods[] = {
  {"init", arraylist_init},
  {"add", arraylist_add},
  {"get", arraylist_get},
  {"getRawArray", arraylist_get_raw},
  {"isEmpty", arraylist_is_empty},
  {"remove", arraylist_remove},
  {"removeIf", arraylist_remove_if},
  {"clear", arraylist_clear},
  {"clone", arraylist_clone},
  {"contains", arraylist_contains},
  {"reserve", arraylist_reserve},
  {"reverse", arraylist_reverse},
  {"slice", arraylist_slice},
  {"toArray", arraylist_to_array},
  {"iterator", arraylist_iterator},
  {"sortBy", arraylist_sortby},
  {"__newindex", arraylist_newindex},
  {"__index", arraylist_index_operator},
  {"__eq", arraylist_eq},
  {"__tostring", arraylist_tostring},
  {NULL, NULL}
};

static int arraylist_of (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  lua_getglobal(L, "ArrayList");
  lua_call(L, 0, 1);
  for (i = 1; i <= nargs; i++) {
    lua_getfield(L, -1, "add");
    lua_pushvalue(L, -2);
    lua_pushvalue(L, i);
    lua_call(L, 2, 0);
  }
  return 1;
}

int luaB_arraylist_init (lua_State *L) {
  int top = lua_gettop(L);
  lua_newtable(L);
  luaL_setfuncs(L, arraylist_methods, 0);
  lua_pushcfunction(L, arraylist_of);
  lua_setfield(L, -2, "of");
  lua_pushboolean(L, 1);
  lua_setfield(L, -2, "__static_of");
  lua_insert(L, 1);
  luaB_setup_class(L);
  lua_pushvalue(L, 1);
  lua_setglobal(L, "ArrayList");
  lua_remove(L, 1);
  lua_settop(L, top);
  return 0;
}
