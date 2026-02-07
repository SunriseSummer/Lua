/*
** $Id: lbaselib_cj.c $
** Cangjie OOP runtime support - extracted from lbaselib.c
** Functions for class/struct instantiation, method binding,
** inheritance chain walking, enum support, tuple, and type checking.
** See Copyright Notice in lua.h
*/

#define lbaselib_cj_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>
#include <stdio.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "lbaselib_cj.h"


/*
** ============================================================
** Cangjie OOP runtime support
** Functions for class/struct instantiation, method binding,
** inheritance chain walking, and type checking.
** ============================================================
*/

/* Upvalue-based bound method: when called, prepend the bound object */
static int cangjie_bound_method (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  int top_before;
  /* upvalue 1 = the original function, upvalue 2 = the bound object */
  lua_pushvalue(L, lua_upvalueindex(1));  /* push function */
  lua_pushvalue(L, lua_upvalueindex(2));  /* push self */
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);  /* push original args */
  }
  top_before = nargs;  /* original args count */
  lua_call(L, nargs + 1, LUA_MULTRET);
  return lua_gettop(L) - top_before;  /* only return the new results */
}

/* Custom __index: if the value from the class table is a function,
** return a bound method; otherwise return the raw value.
** Supports inheritance: walks the __parent chain to find methods.
** Static functions (marked with __static_<name> = true) are returned
** without binding to the instance. */
static int cangjie_index_handler (lua_State *L) {
  /* Arguments: obj (table), key */
  /* upvalue 1 = the class table */
  /* First, check if the key exists in the instance itself */
  lua_pushvalue(L, 2);  /* push key */
  lua_rawget(L, 1);     /* get obj[key] */
  if (!lua_isnil(L, -1)) {
    return 1;  /* found in instance */
  }
  lua_pop(L, 1);
  /* Look up in the class table, walking up parent chain */
  {
    int cls_idx;
    lua_pushvalue(L, lua_upvalueindex(1));  /* start with the class table */
    cls_idx = lua_gettop(L);
    while (!lua_isnil(L, cls_idx)) {
      lua_pushvalue(L, 2);  /* push key */
      lua_rawget(L, cls_idx);  /* rawget to avoid metatable loops */
      if (!lua_isnil(L, -1)) {
        if (lua_isfunction(L, -1)) {
          /* Check if this is a static function (no binding needed) */
          int is_static = 0;
          if (lua_isstring(L, 2)) {
            const char *keystr = lua_tostring(L, 2);
            char marker[128];
            snprintf(marker, sizeof(marker), "__static_%s", keystr);
            lua_getfield(L, cls_idx, marker);
            is_static = lua_toboolean(L, -1);
            lua_pop(L, 1);  /* pop marker value */
          }
          if (is_static) {
            return 1;  /* return static function directly (no binding) */
          }
          /* It's an instance method - create a bound method closure */
          lua_pushvalue(L, -1);  /* function */
          lua_pushvalue(L, 1);   /* obj (self) */
          lua_pushcclosure(L, cangjie_bound_method, 2);
          return 1;
        }
        return 1;  /* return non-function value */
      }
      lua_pop(L, 1);  /* pop nil */
      /* Try parent class */
      lua_getfield(L, cls_idx, "__parent");
      lua_remove(L, cls_idx);  /* remove old class ref */
      cls_idx = lua_gettop(L);
    }
    lua_pop(L, 1);  /* pop nil (end of chain) */
  }
  lua_pushnil(L);
  return 1;  /* not found */
}

static int cangjie_call_handler (lua_State *L) {
  /* Arguments: cls, arg1, arg2, ... (cls is first arg via __call) */
  int nargs = lua_gettop(L) - 1;  /* number of constructor args (excluding cls) */
  int i;
  int obj, mt;
  lua_newtable(L);              /* create new instance: obj = {} */
  /* stack: [cls, arg1, ..., argN, obj] */
  obj = lua_gettop(L);
  /* Store __class reference in instance for type checking */
  lua_pushvalue(L, 1);
  lua_setfield(L, obj, "__class");
  /* Set up metatable for the instance with custom __index */
  lua_newtable(L);              /* instance metatable */
  mt = lua_gettop(L);
  lua_pushvalue(L, 1);          /* push cls as upvalue */
  lua_pushcclosure(L, cangjie_index_handler, 1);
  lua_setfield(L, mt, "__index");
  /* Copy metamethods from class table to instance metatable.
  ** Walk the class hierarchy (__parent chain) to inherit operator overloads. */
  {
    static const char *const metamethods[] = {
      "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
      "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
      "__eq", "__lt", "__le", "__len", "__concat", "__tostring",
      "__newindex",
      NULL
    };
    int cls_walk;
    lua_pushvalue(L, 1);  /* start with the class table */
    cls_walk = lua_gettop(L);
    while (!lua_isnil(L, cls_walk)) {
      int mi;
      for (mi = 0; metamethods[mi] != NULL; mi++) {
        /* Only set if not already set (child overrides parent) */
        lua_getfield(L, mt, metamethods[mi]);
        if (lua_isnil(L, -1)) {
          lua_pop(L, 1);
          lua_getfield(L, cls_walk, metamethods[mi]);
          if (!lua_isnil(L, -1)) {
            lua_setfield(L, mt, metamethods[mi]);
          }
          else {
            lua_pop(L, 1);
          }
        }
        else {
          lua_pop(L, 1);  /* already set */
        }
      }
      /* Walk to parent */
      lua_getfield(L, cls_walk, "__parent");
      lua_remove(L, cls_walk);
      cls_walk = lua_gettop(L);
    }
    lua_pop(L, 1);  /* pop nil (end of chain) */
  }
  lua_setmetatable(L, obj);
  /* Check if cls.init exists */
  lua_getfield(L, 1, "init");
  if (!lua_isnil(L, -1)) {
    /* Call init(obj, arg1, arg2, ...) */
    lua_pushvalue(L, obj);      /* push obj as first arg (self) */
    for (i = 1; i <= nargs; i++) {
      lua_pushvalue(L, i + 1);  /* push arg_i (original args start at index 2) */
    }
    lua_call(L, nargs + 1, 0);  /* call init(obj, arg1, arg2, ...) */
  }
  else {
    lua_pop(L, 1);  /* pop nil */
    /* Auto-constructor: assign args to fields if __nfields is set */
    lua_getfield(L, 1, "__nfields");
    if (lua_isinteger(L, -1)) {
      int nf = (int)lua_tointeger(L, -1);
      int fi;
      lua_pop(L, 1);
      for (fi = 1; fi <= nf && fi <= nargs; fi++) {
        char fieldkey[32];  /* "__field_" + up to 20 digits + NUL */
        snprintf(fieldkey, sizeof(fieldkey), "__field_%d", fi);
        lua_getfield(L, 1, fieldkey);  /* get field name */
        if (lua_isstring(L, -1)) {
          const char *fname = lua_tostring(L, -1);
          lua_pushvalue(L, fi + 1);  /* push arg value */
          lua_setfield(L, obj, fname);  /* obj.fieldname = arg */
        }
        lua_pop(L, 1);  /* pop field name string */
      }
    } else {
      lua_pop(L, 1);
    }
  }
  lua_pushvalue(L, obj);        /* return obj */
  return 1;
}

int luaB_setup_class (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);  /* cls must be a table */
  /* Create metatable for cls: { __call = cangjie_call_handler } */
  lua_newtable(L);
  lua_pushcfunction(L, cangjie_call_handler);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, 1);  /* setmetatable(cls, mt) */
  return 0;
}


/*
** __cangjie_extend_type(typename, methods_table) - Set up a type extension
** so that built-in type values (numbers, strings, booleans) can call
** methods defined in the extension. Uses debug.setmetatable to set up
** a shared metatable with __index pointing to the methods table.
**
** The __index handler wraps method lookups to auto-bind the value as
** the first argument (self), matching Cangjie's method call semantics.
*/
static int cangjie_type_bound_method (lua_State *L) {
  /* upvalue 1 = the original function, upvalue 2 = the bound value */
  int nargs = lua_gettop(L);
  int i;
  int top_before;
  lua_pushvalue(L, lua_upvalueindex(1));  /* push function */
  lua_pushvalue(L, lua_upvalueindex(2));  /* push self (the value) */
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);  /* push original args */
  }
  top_before = nargs;
  lua_call(L, nargs + 1, LUA_MULTRET);
  return lua_gettop(L) - top_before;
}

static int cangjie_type_index_handler (lua_State *L) {
  /* Arguments: value, key */
  /* upvalue 1 = the extension methods table */
  /* upvalue 2 = the original __index (table or function or nil) */

  /* First, check extension methods table */
  lua_pushvalue(L, 2);  /* push key */
  lua_gettable(L, lua_upvalueindex(1));  /* get methods[key] */
  if (!lua_isnil(L, -1)) {
    if (lua_isfunction(L, -1)) {
      /* Wrap function to auto-bind the value as self */
      lua_pushvalue(L, -1);  /* function */
      lua_pushvalue(L, 1);   /* the value (self) */
      lua_pushcclosure(L, cangjie_type_bound_method, 2);
      return 1;
    }
    return 1;  /* return non-nil value as-is */
  }
  lua_pop(L, 1);  /* pop nil */

  /* Fall back to original __index */
  if (lua_isnil(L, lua_upvalueindex(2))) {
    lua_pushnil(L);
    return 1;
  }
  if (lua_istable(L, lua_upvalueindex(2))) {
    lua_pushvalue(L, 2);  /* push key */
    lua_gettable(L, lua_upvalueindex(2));  /* get original[key] */
    return 1;
  }
  if (lua_isfunction(L, lua_upvalueindex(2))) {
    lua_pushvalue(L, lua_upvalueindex(2));  /* push original __index func */
    lua_pushvalue(L, 1);  /* value */
    lua_pushvalue(L, 2);  /* key */
    lua_call(L, 2, 1);
    return 1;
  }
  lua_pushnil(L);
  return 1;
}

/*
** __cangjie_extend_type(typename, methods_table)
** Set up type extension for built-in types (Int64, Float64, String, Bool).
** Creates/updates metatables so that values of these types can call
** extension methods using dot syntax (e.g., 42.double()).
*/
int luaB_extend_type (lua_State *L) {
  const char *tname = luaL_checkstring(L, 1);
  int val_idx;
  luaL_checktype(L, 2, LUA_TTABLE);  /* methods table */

  /* Create a representative value to get/set its metatable */
  if (strcmp(tname, "Int64") == 0 || strcmp(tname, "Float64") == 0) {
    lua_pushinteger(L, 0);  /* representative number */
  }
  else if (strcmp(tname, "String") == 0) {
    lua_pushliteral(L, "");  /* representative string */
  }
  else if (strcmp(tname, "Bool") == 0) {
    lua_pushboolean(L, 0);  /* representative boolean */
  }
  else {
    return luaL_error(L, "cannot extend built-in type '%s'", tname);
  }
  /* stack: [tname, methods, representative_value] */
  val_idx = lua_gettop(L);

  /* Check if value already has a metatable */
  if (lua_getmetatable(L, val_idx)) {
    /* Metatable exists - get current __index, set up wrapped __index */
    /* stack: [tname, methods, val, metatable] */
    lua_getfield(L, -1, "__index");
    /* stack: [tname, methods, val, metatable, old_index] */
    lua_pushvalue(L, 2);   /* push methods table */
    lua_pushvalue(L, -2);  /* push old __index */
    lua_pushcclosure(L, cangjie_type_index_handler, 2);
    lua_setfield(L, -3, "__index");  /* metatable.__index = new handler */
    lua_pop(L, 2);  /* pop old_index and metatable */
  }
  else {
    /* No metatable, create one */
    lua_newtable(L);  /* new metatable */
    lua_pushvalue(L, 2);  /* push methods table */
    lua_pushnil(L);  /* no original __index */
    lua_pushcclosure(L, cangjie_type_index_handler, 2);
    lua_setfield(L, -2, "__index");
    lua_setmetatable(L, val_idx);
  }
  return 0;
}


/*
** __cangjie_copy_to_type(target_table, source_table) - Copy all entries
** from source_table into target_table. Used to populate type proxy tables.
*/
int luaB_copy_to_type (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_pushnil(L);  /* first key */
  while (lua_next(L, 2) != 0) {
    /* stack: target, source, key, value */
    lua_pushvalue(L, -2);  /* push key */
    lua_pushvalue(L, -2);  /* push value */
    lua_settable(L, 1);    /* target[key] = value */
    lua_pop(L, 1);  /* pop value, keep key for next iteration */
  }
  return 0;
}


/*
** __cangjie_set_parent(child_class, parent_class) - Set up inheritance
** relationship. Copies parent methods to child (child overrides take
** priority), sets __parent reference for runtime chain walking.
*/
int luaB_set_parent (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);  /* child class */
  luaL_checktype(L, 2, LUA_TTABLE);  /* parent class */
  /* Set __parent reference */
  lua_pushvalue(L, 2);
  lua_setfield(L, 1, "__parent");
  /* Copy parent methods to child (only those not already defined) */
  lua_pushnil(L);
  while (lua_next(L, 2) != 0) {
    /* stack: child, parent, key, value */
    const char *key;
    if (lua_type(L, -2) == LUA_TSTRING) {
      key = lua_tostring(L, -2);
      /* Skip internal fields and init */
      if (key[0] != '_' && strcmp(key, "init") != 0) {
        /* Only copy if child doesn't already have this key */
        lua_pushvalue(L, -2);  /* push key */
        lua_rawget(L, 1);      /* get child[key] */
        if (lua_isnil(L, -1)) {
          /* Not in child, copy from parent */
          lua_pop(L, 1);  /* pop nil */
          lua_pushvalue(L, -2);  /* push key */
          lua_pushvalue(L, -2);  /* push value */
          lua_rawset(L, 1);      /* child[key] = value */
        }
        else {
          lua_pop(L, 1);  /* pop existing value */
        }
      }
    }
    lua_pop(L, 1);  /* pop value, keep key */
  }
  return 0;
}


/*
** __cangjie_is_instance(obj, cls) - Check if obj is an instance of cls
** (or any of its parent classes). Returns true/false.
*/
int luaB_is_instance (lua_State *L) {
  if (!lua_istable(L, 1) || !lua_istable(L, 2)) {
    lua_pushboolean(L, 0);
    return 1;
  }
  /* Get obj.__class and walk the parent chain */
  lua_getfield(L, 1, "__class");
  while (!lua_isnil(L, -1)) {
    if (lua_rawequal(L, -1, 2)) {
      lua_pushboolean(L, 1);
      return 1;
    }
    lua_getfield(L, -1, "__parent");
    lua_remove(L, -2);
  }
  lua_pushboolean(L, 0);
  return 1;
}



/*
** ============================================================
** Cangjie pattern matching runtime support
** ============================================================
*/

/*
** __cangjie_match_tag(value, tag) - Check if a value's __tag matches tag.
** Used by the pattern matching compiler to dispatch match cases.
*/
int luaB_match_tag (lua_State *L) {
  /* Check if a value's __tag matches a given tag string */
  const char *tag;
  if (!lua_istable(L, 1)) {
    lua_pushboolean(L, 0);
    return 1;
  }
  tag = luaL_checkstring(L, 2);
  lua_getfield(L, 1, "__tag");
  if (lua_isstring(L, -1)) {
    lua_pushboolean(L, strcmp(lua_tostring(L, -1), tag) == 0);
  }
  else {
    lua_pushboolean(L, 0);
  }
  return 1;
}


/*
** __cangjie_match_tuple(value, n) - Check if value is a tuple with n elements.
*/
int luaB_match_tuple (lua_State *L) {
  if (!lua_istable(L, 1)) {
    lua_pushboolean(L, 0);
    return 1;
  }
  lua_getfield(L, 1, "__tuple");
  if (!lua_toboolean(L, -1)) {
    lua_pushboolean(L, 0);
    return 1;
  }
  lua_pop(L, 1);
  lua_getfield(L, 1, "__n");
  if (lua_isinteger(L, -1)) {
    lua_Integer n = lua_tointeger(L, -1);
    lua_Integer expected = luaL_checkinteger(L, 2);
    lua_pushboolean(L, n == expected);
  }
  else {
    lua_pushboolean(L, 0);
  }
  return 1;
}


/*
** __cangjie_setup_enum(enum_table) - Set up enum table so that enum values
** (both constructor results and static values) get a metatable with __index
** pointing to the enum table, enabling method calls on enum values via this.
** Wraps parameterized constructors to set metatable on created values.
*/

/* Helper: wraps an enum constructor to set metatable on result */
static int cangjie_enum_ctor_wrapper (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  /* upvalue 1 = original constructor, upvalue 2 = enum metatable */
  lua_pushvalue(L, lua_upvalueindex(1));  /* push original ctor */
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);
  }
  lua_call(L, nargs, 1);  /* call original ctor */
  /* Set metatable on the result (if it's a table) */
  if (lua_istable(L, -1)) {
    lua_pushvalue(L, lua_upvalueindex(2));  /* push mt */
    lua_setmetatable(L, -2);
  }
  return 1;
}

/* __index handler for enum values: looks up in enum table, auto-binds methods */
static int cangjie_enum_index_handler (lua_State *L) {
  /* Arguments: obj (enum value), key */
  /* upvalue 1 = the enum table */
  /* First, check raw access on the instance */
  lua_pushvalue(L, 2);  /* push key */
  lua_rawget(L, 1);
  if (!lua_isnil(L, -1)) {
    return 1;  /* found in instance */
  }
  lua_pop(L, 1);
  /* Look up in enum table */
  lua_pushvalue(L, 2);  /* push key */
  lua_rawget(L, lua_upvalueindex(1));
  if (!lua_isnil(L, -1)) {
    if (lua_isfunction(L, -1)) {
      /* Method: create bound closure */
      lua_pushvalue(L, -1);  /* function */
      lua_pushvalue(L, 1);   /* obj (self) */
      lua_pushcclosure(L, cangjie_bound_method, 2);
      return 1;
    }
    return 1;  /* non-function value */
  }
  lua_pushnil(L);
  return 1;
}

/*
** __cangjie_setup_enum(enum_table)
** Set up enum table metatables so enum values can call member functions.
** Wraps parameterized constructors to auto-set metatables on results.
*/
int luaB_setup_enum (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);  /* enum table */
  /* Create a metatable for enum values:
  ** { __index = cangjie_enum_index_handler(enum_table) }
  */
  lua_newtable(L);  /* mt = {} */
  lua_pushvalue(L, 1);  /* push enum table as upvalue */
  lua_pushcclosure(L, cangjie_enum_index_handler, 1);
  lua_setfield(L, -2, "__index");  /* mt.__index = handler */
  /* Stack: [enum_table, mt] */

  {
    int mt_idx = lua_gettop(L);  /* index of mt */
    /* Collect keys of functions to wrap */
    int nfuncs = 0;
    const char *func_keys[64];
    lua_pushnil(L);  /* first key */
    while (lua_next(L, 1) != 0) {
      /* key at -2, value at -1 */
      if (lua_type(L, -2) == LUA_TSTRING) {
        if (lua_istable(L, -1)) {
          lua_getfield(L, -1, "__tag");
          if (lua_isstring(L, -1)) {
            /* No-arg enum value: set metatable */
            lua_pop(L, 1);  /* pop __tag */
            lua_pushvalue(L, mt_idx);  /* push mt */
            lua_setmetatable(L, -2);
          }
          else {
            lua_pop(L, 1);  /* pop nil */
          }
        }
        else if (lua_isfunction(L, -1) && nfuncs < 64) {
          const char *key = lua_tostring(L, -2);
          /* Skip internal fields and methods (only wrap constructors) */
          if (key[0] != '_') {
            /* Check if this looks like a constructor (capitalized name) */
            if (key[0] >= 'A' && key[0] <= 'Z') {
              func_keys[nfuncs++] = key;
            }
          }
        }
      }
      lua_pop(L, 1);  /* pop value, keep key */
    }
    /* Now wrap collected constructor keys */
    {
      int fi;
      for (fi = 0; fi < nfuncs; fi++) {
        lua_getfield(L, 1, func_keys[fi]);  /* push original ctor */
        lua_pushvalue(L, mt_idx);  /* push mt */
        lua_pushcclosure(L, cangjie_enum_ctor_wrapper, 2);  /* wrap */
        lua_setfield(L, 1, func_keys[fi]);  /* enum_table[key] = wrapper */
        /* Also update global if it exists */
        lua_getglobal(L, func_keys[fi]);
        if (lua_isfunction(L, -1)) {
          lua_pop(L, 1);
          lua_getfield(L, 1, func_keys[fi]);  /* get wrapped version */
          lua_setglobal(L, func_keys[fi]);  /* update global */
        }
        else {
          lua_pop(L, 1);
        }
      }
    }
  }

  lua_pop(L, 1);  /* pop mt */
  return 0;
}


/*
** __cangjie_tuple(...) - Create a tuple value.
** Returns a table { [0]=arg1, [1]=arg2, ..., __n=count, __tuple=true }
*/
int luaB_tuple (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  int tbl;
  lua_newtable(L);
  tbl = lua_gettop(L);
  for (i = 1; i <= nargs; i++) {
    lua_pushvalue(L, i);
    lua_rawseti(L, tbl, i - 1);  /* 0-based indexing */
  }
  lua_pushinteger(L, nargs);
  lua_setfield(L, tbl, "__n");
  lua_pushboolean(L, 1);
  lua_setfield(L, tbl, "__tuple");
  return 1;
}


/*
** ============================================================
** Function overloading support
** ============================================================
*/

/* Dispatcher for overloaded functions.
** Upvalue 1 = overload table { [nparams] = func, ... }
** Selects the overload matching the number of arguments, or falls
** back to the closest overload with more parameters (for defaults). */
static int cangjie_overload_dispatch (lua_State *L) {
  int nargs = lua_gettop(L);
  /* Look up exact match first */
  lua_pushinteger(L, nargs);
  lua_gettable(L, lua_upvalueindex(1));
  if (!lua_isnil(L, -1)) {
    /* Found exact match - call it */
    lua_insert(L, 1);  /* move function to bottom */
    lua_call(L, nargs, LUA_MULTRET);
    return lua_gettop(L);  /* all results */
  }
  lua_pop(L, 1);
  /* No exact match: try to find an overload that can accept these args
  ** (one with more params, relying on default values).
  ** Iterate over the overload table to find the best match. */
  {
    int best_nparams = -1;
    lua_pushnil(L);
    while (lua_next(L, lua_upvalueindex(1)) != 0) {
      if (lua_isinteger(L, -2)) {
        int np = (int)lua_tointeger(L, -2);
        if (np > nargs && (best_nparams < 0 || np < best_nparams)) {
          best_nparams = np;
        }
      }
      lua_pop(L, 1);  /* pop value, keep key */
    }
    if (best_nparams >= 0) {
      lua_pushinteger(L, best_nparams);
      lua_gettable(L, lua_upvalueindex(1));
      lua_insert(L, 1);
      lua_call(L, nargs, LUA_MULTRET);
      return lua_gettop(L);
    }
    /* Also try overloads with fewer params (vararg or flexible matching) */
    best_nparams = -1;
    lua_pushnil(L);
    while (lua_next(L, lua_upvalueindex(1)) != 0) {
      if (lua_isinteger(L, -2)) {
        int np = (int)lua_tointeger(L, -2);
        if (np < nargs && (best_nparams < 0 || np > best_nparams)) {
          best_nparams = np;
        }
      }
      lua_pop(L, 1);
    }
    if (best_nparams >= 0) {
      lua_pushinteger(L, best_nparams);
      lua_gettable(L, lua_upvalueindex(1));
      lua_insert(L, 1);
      lua_call(L, nargs, LUA_MULTRET);
      return lua_gettop(L);
    }
  }
  return luaL_error(L, "no overload matches %d argument(s)", nargs);
}

/*
** __cangjie_overload(old_value, new_func, new_nparams)
** If old_value is nil, creates a new dispatcher with just new_func.
** If old_value is already an overload dispatcher, adds new_func to it.
** new_nparams is the parameter count passed explicitly by the compiler.
** Returns the (updated) dispatcher.
*/
int luaB_overload (lua_State *L) {
  int new_nparams;
  /* arg 1 = old value, arg 2 = new function, arg 3 = nparams (int) */
  new_nparams = (int)luaL_checkinteger(L, 3);

  if (lua_isnil(L, 1)) {
    /* First definition: create a new dispatcher with one entry */
    int tbl;
    lua_newtable(L);
    tbl = lua_gettop(L);
    lua_pushboolean(L, 1);
    lua_setfield(L, tbl, "__overload");
    lua_pushinteger(L, new_nparams);
    lua_pushvalue(L, 2);
    lua_settable(L, tbl);
    lua_pushcclosure(L, cangjie_overload_dispatch, 1);
    return 1;
  }

  /* Check if old value is already an overload dispatcher */
  if (lua_isfunction(L, 1)) {
    if (lua_getupvalue(L, 1, 1) != NULL) {
      if (lua_istable(L, -1)) {
        lua_getfield(L, -1, "__overload");
        if (lua_toboolean(L, -1)) {
          int tbl_idx;
          lua_pop(L, 1);  /* pop marker */
          tbl_idx = lua_gettop(L);  /* the overload table */
          /* Add new overload */
          lua_pushinteger(L, new_nparams);
          lua_pushvalue(L, 2);
          lua_settable(L, tbl_idx);
          /* Return old dispatcher (now updated via upvalue) */
          lua_pushvalue(L, 1);
          return 1;
        }
        lua_pop(L, 1);  /* pop non-marker */
      }
      lua_pop(L, 1);  /* pop upvalue */
    }
  }

  /* Old value exists but is not an overload dispatcher - just replace */
  lua_pushvalue(L, 2);
  return 1;
}


/*
** __cangjie_named_call(func, pos1, ..., posN, npos, named_table)
** Call 'func' with a mixture of positional and named arguments.
** Positional arguments come first, then named arguments are matched to
** parameter positions using the function's debug info (parameter names).
** - func: the function to call
** - pos1..posN: positional arguments
** - npos: number of positional arguments
** - named_table: table { paramName = value, ... }
*/
int luaB_named_call (lua_State *L) {
  int nargs = lua_gettop(L);
  int npos, total_params, i;
  lua_Debug ar;

  /* Stack: func, pos1, ..., posN, npos, named_table */
  if (nargs < 3) {
    return luaL_error(L, "__cangjie_named_call: requires at least 3 arguments");
  }

  npos = (int)lua_tointeger(L, nargs - 1);

  /* Get function's parameter count using debug API */
  lua_pushvalue(L, 1);  /* push func for getinfo */
  if (!lua_getinfo(L, ">u", &ar)) {
    return luaL_error(L, "__cangjie_named_call: cannot get function info");
  }
  total_params = ar.nparams;

  /* Build the call: push func, then all args in parameter order */
  lua_pushvalue(L, 1);  /* push func */

  for (i = 1; i <= total_params; i++) {
    if (i <= npos) {
      /* Use the positional argument (at stack position 1 + i) */
      lua_pushvalue(L, 1 + i);
    }
    else {
      /* Look up this parameter's name and find it in named_table */
      const char *pname;
      lua_pushvalue(L, 1);  /* push func on top for lua_getlocal */
      pname = lua_getlocal(L, NULL, i);
      lua_pop(L, 1);  /* pop the func we pushed */
      if (pname != NULL) {
        /* Look up pname in the named_table (last argument) */
        lua_getfield(L, nargs, pname);
      }
      else {
        lua_pushnil(L);
      }
    }
  }

  /* Call func with total_params arguments, returning all results */
  lua_call(L, total_params, LUA_MULTRET);
  return lua_gettop(L) - nargs;
}


/*
** Array<Type>(size, init) constructor.
** Creates a 0-based array table with __n = size.
** If init is a function, calls init(i) for each index.
** Otherwise uses init as the value for all elements.
*/
int luaB_array_init (lua_State *L) {
  int size = (int)luaL_checkinteger(L, 1);
  int tbl, i;
  luaL_checkany(L, 2);
  lua_newtable(L);
  tbl = lua_gettop(L);
  for (i = 0; i < size; i++) {
    if (lua_isfunction(L, 2)) {
      lua_pushvalue(L, 2);      /* push init function */
      lua_pushinteger(L, i);    /* push index (0-based) */
      lua_call(L, 1, 1);        /* call init(i) */
    } else {
      lua_pushvalue(L, 2);      /* push init value */
    }
    lua_rawseti(L, tbl, i);     /* arr[i] = value */
  }
  lua_pushinteger(L, size);
  lua_setfield(L, tbl, "__n");
  return 1;
}
