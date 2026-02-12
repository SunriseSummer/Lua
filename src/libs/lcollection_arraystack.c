/*
** ArrayStack implementation for Cangjie collection package.
*/

#define lcollection_arraystack_c
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



static int arraystack_init (lua_State *L) {
  int self = 1;
  lua_Integer capacity = 8;
  if (lua_gettop(L) > 1) {
    capacity = luaL_checkinteger(L, 2);
    luaL_argcheck(L, capacity >= 0, 2, "capacity must be non-negative");
  }
  if (capacity < 8)
    capacity = 8;
  lua_pushinteger(L, capacity);
  lua_setfield(L, self, "capacity");
  set_size(L, self, 0);
  get_data_table(L, self);
  lua_pop(L, 1);
  return 0;
}


static int arraystack_add (lua_State *L) {
  int self = 1;
  int data_idx = get_data_table(L, self);
  lua_Integer size = get_int_field(L, self, "size", 0);
  ensure_capacity(L, self, size + 1);
  lua_pushvalue(L, 2);
  lua_rawseti(L, data_idx, size);
  set_size(L, self, size + 1);
  lua_pop(L, 1);
  return 0;
}


static int arraystack_is_empty (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_pushboolean(L, size == 0);
  return 1;
}


static int arraystack_peek (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  if (size <= 0) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  lua_rawgeti(L, data_idx, size - 1);
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}


static int arraystack_remove (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  if (size <= 0) {
    lua_pop(L, 1);
    push_none(L);
    return 1;
  }
  lua_rawgeti(L, data_idx, size - 1);
  lua_pushnil(L);
  lua_rawseti(L, data_idx, size - 1);
  set_size(L, 1, size - 1);
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}


static int arraystack_clear (lua_State *L) {
  lua_newtable(L);
  lua_setfield(L, 1, "__data");
  set_size(L, 1, 0);
  return 0;
}


static int arraystack_iterator_next (lua_State *L) {
  lua_Integer idx = lua_tointeger(L, lua_upvalueindex(2));
  int stack_idx = lua_upvalueindex(1);
  idx--;
  lua_pushinteger(L, idx);
  lua_copy(L, -1, lua_upvalueindex(2));
  lua_pop(L, 1);
  if (idx < 0) {
    push_none(L);
    return 1;
  }
  lua_getfield(L, stack_idx, "__data");
  lua_rawgeti(L, -1, idx);
  push_some(L, -1);
  lua_remove(L, -2);
  lua_remove(L, -2);
  return 1;
}


static int arraystack_iterator (lua_State *L) {
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_pushvalue(L, 1);
  lua_pushinteger(L, size);
  lua_pushcclosure(L, arraystack_iterator_next, 2);
  return 1;
}


static int arraystack_reserve (lua_State *L) {
  lua_Integer additional = luaL_checkinteger(L, 2);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  if (additional <= 0)
    return 0;
  ensure_capacity(L, 1, size + additional);
  return 0;
}


static int arraystack_to_array (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  lua_newtable(L);
  for (i = 0; i < size; i++) {
    /* Convert LIFO stack order (top-first) into array order. */
    lua_rawgeti(L, data_idx, size - 1 - i);
    lua_rawseti(L, -2, i);
  }
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, size);
  lua_setfield(L, -2, "size");
  lua_remove(L, data_idx);
  return 1;
}


static int arraystack_tostring (lua_State *L) {
  int data_idx = get_data_table(L, 1);
  lua_Integer size = get_int_field(L, 1, "size", 0);
  lua_Integer i;
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '[');
  for (i = 0; i < size; i++) {
    if (i > 0)
      luaL_addstring(&b, ", ");
    lua_rawgeti(L, data_idx, size - 1 - i);
    luaL_addvalue(&b);
  }
  luaL_addchar(&b, ']');
  luaL_pushresult(&b);
  lua_remove(L, data_idx);
  return 1;
}


static const luaL_Reg arraystack_methods[] = {
  {"init", arraystack_init},
  {"add", arraystack_add},
  {"clear", arraystack_clear},
  {"isEmpty", arraystack_is_empty},
  {"iterator", arraystack_iterator},
  {"peek", arraystack_peek},
  {"remove", arraystack_remove},
  {"reserve", arraystack_reserve},
  {"toArray", arraystack_to_array},
  {"toString", arraystack_tostring},
  {"__tostring", arraystack_tostring},
  {NULL, NULL}
};


int luaB_arraystack_init (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, arraystack_methods, 0);
  cangjie_register_class_global(L, "ArrayStack");
  return 0;
}
