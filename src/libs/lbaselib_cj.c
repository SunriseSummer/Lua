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
#include <math.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "lbaselib_cj.h"


/*
** ============================================================
** Shared metamethod name lists
** These are the Lua metamethod names that need to be copied from
** class/enum tables into instance metatables so that operators work.
** ============================================================
*/

/* Metamethods copied for class instances (excludes __call). */
static const char *const cj_class_metamethods[] = {
  "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
  "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__eq", "__lt", "__le", "__len", "__concat", "__tostring",
  "__newindex",
  NULL
};

/* Metamethods copied for enum values (includes __call, no __newindex). */
static const char *const cj_enum_metamethods[] = {
  "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
  "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__eq", "__lt", "__le", "__len", "__concat", "__call",
  "__tostring",
  NULL
};


/*
** ============================================================
** Bound method helper and instance __index handler
** ============================================================
*/

/* Upvalue-based bound method: when called, prepend the bound object.
** Used by class instances, type extensions, enum values, and Option. */
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
    int cls_walk;
    lua_pushvalue(L, 1);  /* start with the class table */
    cls_walk = lua_gettop(L);
    while (!lua_isnil(L, cls_walk)) {
      int mi;
      for (mi = 0; cj_class_metamethods[mi] != NULL; mi++) {
        /* Only set if not already set (child overrides parent) */
        lua_getfield(L, mt, cj_class_metamethods[mi]);
        if (lua_isnil(L, -1)) {
          lua_pop(L, 1);
          lua_getfield(L, cls_walk, cj_class_metamethods[mi]);
          if (!lua_isnil(L, -1)) {
            lua_setfield(L, mt, cj_class_metamethods[mi]);
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

/*
** ============================================================
** Class setup and instantiation
** ============================================================
*/

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
** ============================================================
** Type extension support
** Enables built-in types (Int64, Float64, String, Bool) to have
** extension methods callable via dot syntax.
** ============================================================
*/

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
      lua_pushcclosure(L, cangjie_bound_method, 2);
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
/* C function: Float64.GetPI() returns pi */
static int cangjie_float64_getpi (lua_State *L) {
  UNUSED(L);
  lua_pushnumber(L, M_PI);
  return 1;
}

/* C function: Float64(value) converts to float (called via __call on table) */
static int cangjie_float64_call (lua_State *L) {
  /* First arg is the table itself (Float64), second is the value to convert */
  lua_remove(L, 1);  /* remove table, shift args down */
  return luaB_cangjie_float64(L);
}

/* __call wrappers: remove the table-self first argument, then delegate
** to the standalone conversion function.  Each built-in type table
** (Int64, Float64, String, Bool) uses one of these as its __call. */
static int cangjie_int64_call (lua_State *L) {
  lua_remove(L, 1);
  return luaB_cangjie_int64(L);
}

static int cangjie_string_call (lua_State *L) {
  lua_remove(L, 1);
  return luaB_cangjie_string(L);
}

static int cangjie_bool_call (lua_State *L) {
  lua_remove(L, 1);
  return luaB_cangjie_bool(L);
}


/*
** ============================================================
** Type conversion functions: Int64(), Float64(), String(), Bool(), Rune()
** These are registered as globals and handle various type conversions
** as specified by the Cangjie language specification.
** ============================================================
*/

/*
** Helper: Determine UTF-8 byte length from lead byte.
** Returns 1-4 for valid lead bytes, 0 for invalid.
*/
static int utf8_char_len (unsigned char c0) {
  if ((c0 & 0x80) == 0) return 1;
  if ((c0 & 0xE0) == 0xC0) return 2;
  if ((c0 & 0xF0) == 0xE0) return 3;
  if ((c0 & 0xF8) == 0xF0) return 4;
  return 0;  /* invalid UTF-8 lead byte */
}


/*
** Helper: Decode a single UTF-8 character from a string of exactly 'len' bytes.
** Returns the code point, or -1 if the string is not a valid single UTF-8 char.
*/
static long utf8_decode_single (const char *s, size_t len) {
  unsigned long cp;
  int nbytes, i;
  if (len == 0) return -1;
  nbytes = utf8_char_len((unsigned char)s[0]);
  if (nbytes == 0 || (size_t)nbytes != len) return -1;
  cp = (unsigned char)s[0];
  if (nbytes == 1) return (long)cp;
  /* mask off the lead byte prefix bits */
  if (nbytes == 2) cp &= 0x1F;
  else if (nbytes == 3) cp &= 0x0F;
  else cp &= 0x07;
  for (i = 1; i < nbytes; i++) {
    unsigned char ci = (unsigned char)s[i];
    if ((ci & 0xC0) != 0x80) return -1;  /* invalid continuation byte */
    cp = (cp << 6) | (ci & 0x3F);
  }
  return (long)cp;
}


/*
** Helper: Encode a Unicode code point as UTF-8 into buf.
** Returns the number of bytes written (1-4), or 0 if invalid code point.
** buf must have space for at least 4 bytes.
*/
static int utf8_encode (lua_Integer cp, char *buf) {
  if (cp < 0 || cp > 0x10FFFF) return 0;
  if (cp <= 0x7F) {
    buf[0] = (char)cp;
    return 1;
  } else if (cp <= 0x7FF) {
    buf[0] = (char)(0xC0 | (cp >> 6));
    buf[1] = (char)(0x80 | (cp & 0x3F));
    return 2;
  } else if (cp <= 0xFFFF) {
    buf[0] = (char)(0xE0 | (cp >> 12));
    buf[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
    buf[2] = (char)(0x80 | (cp & 0x3F));
    return 3;
  } else {
    buf[0] = (char)(0xF0 | (cp >> 18));
    buf[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    buf[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    buf[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
  }
}

/* Int64(value) - convert to integer.
** For numbers: truncates float to integer, passes integer through.
** For strings: parses as number ("123" -> 123); errors if parse fails.
** For booleans: true -> 1, false -> 0.
*/
int luaB_cangjie_int64 (lua_State *L) {
  switch (lua_type(L, 1)) {
    case LUA_TNUMBER: {
      if (lua_isinteger(L, 1)) {
        lua_pushvalue(L, 1);  /* already integer */
      } else {
        lua_Number n = lua_tonumber(L, 1);
        lua_pushinteger(L, (lua_Integer)n);  /* truncate */
      }
      return 1;
    }
    case LUA_TSTRING: {
      size_t len;
      const char *s = lua_tolstring(L, 1, &len);
      if (len == 0)
        return luaL_error(L, "cannot convert empty string to Int64");
      /* Try to parse as a number */
      if (lua_stringtonumber(L, s) != 0) {
        if (lua_isinteger(L, -1)) {
          return 1;
        } else {
          lua_Number n = lua_tonumber(L, -1);
          lua_pop(L, 1);
          lua_pushinteger(L, (lua_Integer)n);
          return 1;
        }
      }
      return luaL_error(L, "cannot convert string '%s' to Int64", s);
    }
    case LUA_TBOOLEAN: {
      lua_pushinteger(L, lua_toboolean(L, 1) ? 1 : 0);
      return 1;
    }
    default:
      return luaL_error(L, "cannot convert %s to Int64",
                        luaL_typename(L, 1));
  }
}


/* Float64(value) - convert to float
** - Float64("3.14") -> parse string as float
** - Float64(42) -> integer to float (42.0)
** - Float64(3.14) -> identity
*/
int luaB_cangjie_float64 (lua_State *L) {
  switch (lua_type(L, 1)) {
    case LUA_TNUMBER: {
      lua_pushnumber(L, lua_tonumber(L, 1));
      return 1;
    }
    case LUA_TSTRING: {
      const char *s = lua_tostring(L, 1);
      if (lua_stringtonumber(L, s) != 0) {
        lua_pushnumber(L, lua_tonumber(L, -1));
        return 1;
      }
      return luaL_error(L, "cannot convert string '%s' to Float64", s);
    }
    default:
      return luaL_error(L, "cannot convert %s to Float64",
                        luaL_typename(L, 1));
  }
}


/* String(value) - convert to string
** - String(65) -> "65" (number to string representation)
** - String(3.14) -> "3.14"
** - String(true) -> "true"
** - String(false) -> "false"
*/
int luaB_cangjie_string (lua_State *L) {
  switch (lua_type(L, 1)) {
    case LUA_TNUMBER: {
      /* Number -> string representation (both integer and float) */
      luaL_tolstring(L, 1, NULL);
      return 1;
    }
    case LUA_TBOOLEAN: {
      lua_pushstring(L, lua_toboolean(L, 1) ? "true" : "false");
      return 1;
    }
    case LUA_TSTRING: {
      lua_pushvalue(L, 1);  /* identity */
      return 1;
    }
    case LUA_TNIL: {
      lua_pushliteral(L, "nil");
      return 1;
    }
    default: {
      luaL_tolstring(L, 1, NULL);
      return 1;
    }
  }
}


/* Bool(value) - convert to boolean
** - Bool("true") -> true
** - Bool("false") -> false
*/
int luaB_cangjie_bool (lua_State *L) {
  switch (lua_type(L, 1)) {
    case LUA_TSTRING: {
      const char *s = lua_tostring(L, 1);
      if (strcmp(s, "true") == 0) {
        lua_pushboolean(L, 1);
        return 1;
      } else if (strcmp(s, "false") == 0) {
        lua_pushboolean(L, 0);
        return 1;
      }
      return luaL_error(L, "cannot convert string '%s' to Bool", s);
    }
    case LUA_TBOOLEAN: {
      lua_pushvalue(L, 1);  /* identity */
      return 1;
    }
    default:
      return luaL_error(L, "cannot convert %s to Bool",
                        luaL_typename(L, 1));
  }
}


/* Rune(value) - type conversion to/from Rune (integer code point).
** - Rune(0x4E50) -> "乐"  (integer code point -> UTF-8 string)
** - Rune(65) -> "A"
** - Rune('x') -> 120      (single-char string -> integer code point)
** - Rune("好") -> 0x597d
*/
int luaB_cangjie_rune (lua_State *L) {
  if (lua_type(L, 1) == LUA_TSTRING) {
    /* Single-char string -> integer code point */
    size_t slen;
    const char *s = lua_tolstring(L, 1, &slen);
    long cp;
    if (slen == 0)
      return luaL_error(L, "Rune() cannot convert empty string");
    cp = utf8_decode_single(s, slen);
    if (cp >= 0) {
      lua_pushinteger(L, (lua_Integer)cp);
      return 1;
    }
    return luaL_error(L, "Rune() requires a single-character string");
  }
  {
    lua_Integer cp = luaL_checkinteger(L, 1);
    char buf[8];
    int len = utf8_encode(cp, buf);
    if (len == 0) {
      return luaL_error(L, "invalid Unicode code point: %I",
                        (LUAI_UACINT)cp);
    }
    lua_pushlstring(L, buf, (size_t)len);
    return 1;
  }
}


int luaB_extend_type (lua_State *L) {
  const char *tname = luaL_checkstring(L, 1);
  int val_idx;
  luaL_checktype(L, 2, LUA_TTABLE);  /* methods table */

  /* For Float64, add built-in static methods and __call metamethod */
  if (strcmp(tname, "Float64") == 0) {
    lua_getfield(L, 2, "GetPI");
    if (lua_isnil(L, -1)) {
      lua_pop(L, 1);
      lua_pushcfunction(L, cangjie_float64_getpi);
      lua_setfield(L, 2, "GetPI");
      lua_pushboolean(L, 1);
      lua_setfield(L, 2, "__static_GetPI");
    }
    else {
      lua_pop(L, 1);
    }
  }

  /* Set up __call metamethod for type conversion on all built-in types */
  {
    lua_CFunction call_fn = NULL;
    if (strcmp(tname, "Int64") == 0) call_fn = cangjie_int64_call;
    else if (strcmp(tname, "Float64") == 0) call_fn = cangjie_float64_call;
    else if (strcmp(tname, "String") == 0) call_fn = cangjie_string_call;
    else if (strcmp(tname, "Bool") == 0) call_fn = cangjie_bool_call;
    if (call_fn != NULL) {
      int has_mt;
      has_mt = lua_getmetatable(L, 2);
      if (!has_mt) {
        lua_newtable(L);
      }
      lua_pushcfunction(L, call_fn);
      lua_setfield(L, -2, "__call");
      lua_setmetatable(L, 2);
    }
  }

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
** ============================================================
** Inheritance and type-checking support
** ============================================================
*/

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
** __cangjie_super_init(self, current_class, args...) - Call parent class constructor.
** Uses current_class (the class where super() is written) to find __parent,
** avoiding infinite recursion when multi-level inheritance is used.
*/
int luaB_super_init (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  /* arg 1 = self, arg 2 = current_class */
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TTABLE);
  /* Get current_class.__parent */
  lua_getfield(L, 2, "__parent");
  if (lua_isnil(L, -1)) {
    return luaL_error(L, "super: class has no parent");
  }
  /* Get __parent.init */
  lua_getfield(L, -1, "init");
  if (lua_isnil(L, -1)) {
    /* No explicit init in parent - just return */
    lua_pop(L, 2);  /* pop nil, parent */
    return 0;
  }
  /* Call parent.init(self, args...) — skip arg 2 (current_class) */
  lua_pushvalue(L, 1);  /* push self */
  for (i = 3; i <= nargs; i++) {
    lua_pushvalue(L, i);  /* push remaining args (skip current_class) */
  }
  lua_call(L, nargs - 1, 0);  /* call init, discard return */
  lua_pop(L, 1);  /* pop parent */
  return 0;
}


/*
** __cangjie_apply_interface(target, iface) - Apply interface default
** implementations to a class/type table. Copies all methods from the
** interface table that are not already defined in the target.
** Unlike __cangjie_set_parent, this also copies metamethods (__xxx).
*/
int luaB_apply_interface (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);  /* target class/type */
  luaL_checktype(L, 2, LUA_TTABLE);  /* interface table */
  lua_pushnil(L);
  while (lua_next(L, 2) != 0) {
    /* stack: target, iface, key, value */
    if (lua_type(L, -2) == LUA_TSTRING && lua_isfunction(L, -1)) {
      /* Only copy function values (skip non-function entries) */
      lua_pushvalue(L, -2);  /* push key */
      lua_rawget(L, 1);      /* get target[key] */
      if (lua_isnil(L, -1)) {
        /* Not in target, copy from interface */
        lua_pop(L, 1);  /* pop nil */
        lua_pushvalue(L, -2);  /* push key */
        lua_pushvalue(L, -2);  /* push value */
        lua_rawset(L, 1);      /* target[key] = value */
      }
      else {
        lua_pop(L, 1);  /* pop existing value */
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
** Iterator support
** ============================================================
*/

/*
** __cangjie_iter(value) - Create an iterator for for-in loops.
** If value is a table (array), returns a value-only iterator
** (skipping array indices). For other iterables, pass through.
*/
static int cangjie_array_iter_next (lua_State *L) {
  /* upvalue 1 = array table, upvalue 2 = current index (integer) */
  lua_Integer i = lua_tointeger(L, lua_upvalueindex(2));
  lua_Integer n;
  i++;
  lua_pushinteger(L, i);
  lua_copy(L, -1, lua_upvalueindex(2));  /* update index */
  lua_pop(L, 1);
  /* Check bounds using __n field */
  lua_getfield(L, lua_upvalueindex(1), "__n");
  n = lua_isinteger(L, -1) ? lua_tointeger(L, -1) : 0;
  lua_pop(L, 1);
  if (i >= n) {
    lua_pushnil(L);
    return 1;  /* return nil to stop iteration */
  }
  lua_pushinteger(L, i);
  lua_gettable(L, lua_upvalueindex(1));  /* get array[i] */
  return 1;  /* return value */
}

int luaB_iter (lua_State *L) {
  if (lua_istable(L, 1)) {
    /* For tables: create a closure iterator that yields values (0-based) */
    lua_pushvalue(L, 1);       /* push table as upvalue 1 */
    lua_pushinteger(L, -1);    /* push initial index as upvalue 2 (will be incremented to 0) */
    lua_pushcclosure(L, cangjie_array_iter_next, 2);
    lua_pushnil(L);            /* state (unused) */
    lua_pushnil(L);            /* initial control value */
    return 3;  /* return iterator, state, initial */
  }
  else if (lua_isfunction(L, 1)) {
    /* Already an iterator function, pass through */
    lua_pushvalue(L, 1);
    lua_pushnil(L);
    lua_pushnil(L);
    return 3;
  }
  return luaL_error(L, "cannot iterate over %s", luaL_typename(L, 1));
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
** ============================================================
** Enum support
** ============================================================
*/

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

  /* Copy metamethods from enum table to metatable.
  ** Lua requires metamethods to be directly in the metatable, not behind __index. */
  {
    int mi;
    for (mi = 0; cj_enum_metamethods[mi] != NULL; mi++) {
      lua_getfield(L, 1, cj_enum_metamethods[mi]);
      if (!lua_isnil(L, -1)) {
        lua_setfield(L, -2, cj_enum_metamethods[mi]);  /* mt[metamethod] = value */
      }
      else {
        lua_pop(L, 1);
      }
    }
  }

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
  lua_pushinteger(L, nargs);
  lua_setfield(L, tbl, "size");
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
  int real_func_idx;  /* stack index of the real Lua function */
  int call_base;  /* stack index where the call frame starts */
  lua_Debug ar;

  /* Stack: func, pos1, ..., posN, npos, named_table */
  if (nargs < 3) {
    return luaL_error(L, "__cangjie_named_call: requires at least 3 arguments");
  }

  npos = (int)lua_tointeger(L, nargs - 1);

  /* The function at position 1 may be an overload dispatcher (C closure).
  ** We need to unwrap it to find the real Lua function for introspection
  ** (parameter count and names via debug API). */
  real_func_idx = 1;  /* default: use the function as-is */
  if (lua_iscfunction(L, 1)) {
    /* Check if it's an overload dispatcher by inspecting its upvalue */
    if (lua_getupvalue(L, 1, 1) != NULL) {
      if (lua_istable(L, -1)) {
        int tbl_idx = lua_gettop(L);
        lua_getfield(L, tbl_idx, "__overload");
        if (lua_toboolean(L, -1)) {
          /* It's an overload dispatcher. Find the best matching overload.
          ** Strategy: find the overload with the smallest nparams >= npos
          ** (since named args fill remaining params via defaults). */
          int best_np = -1;
          lua_pop(L, 1);  /* pop __overload marker */
          lua_pushnil(L);
          while (lua_next(L, tbl_idx) != 0) {
            if (lua_isinteger(L, -2) && lua_isfunction(L, -1)) {
              int np = (int)lua_tointeger(L, -2);
              if (np >= npos && (best_np < 0 || np < best_np)) {
                best_np = np;
              }
            }
            lua_pop(L, 1);  /* pop value, keep key */
          }
          if (best_np >= 0) {
            lua_pushinteger(L, best_np);
            lua_gettable(L, tbl_idx);
            real_func_idx = lua_gettop(L);
          }
          else {
            lua_pop(L, 1);  /* pop table */
          }
        }
        else {
          lua_pop(L, 2);  /* pop non-marker + table */
        }
      }
      else {
        lua_pop(L, 1);  /* pop non-table upvalue */
      }
    }
  }

  /* Determine parameter count using debug API */
  lua_pushvalue(L, real_func_idx);  /* push func for getinfo */
  if (!lua_getinfo(L, ">u", &ar)) {
    return luaL_error(L, "__cangjie_named_call: cannot get function info");
  }
  total_params = ar.nparams;

  /* Build the call: push the real function, then all args in parameter order */
  lua_pushvalue(L, real_func_idx);
  call_base = lua_gettop(L);

  for (i = 1; i <= total_params; i++) {
    if (i <= npos) {
      /* Use the positional argument (at stack position 1 + i) */
      lua_pushvalue(L, 1 + i);
    }
    else {
      /* Look up this parameter's name and find it in named_table */
      const char *pname;
      lua_pushvalue(L, real_func_idx);  /* push func for lua_getlocal */
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
  /* Results are from call_base onwards (call_base slot itself is consumed).
  ** If we had extra items from unwrapping the overload dispatcher
  ** (between nargs and call_base), move results down. */
  {
    int nresults = lua_gettop(L) - call_base + 1;
    if (call_base > nargs + 1) {
      /* Move results down over the extra items */
      for (i = 0; i < nresults; i++) {
        lua_copy(L, call_base + i, nargs + 1 + i);
      }
      lua_settop(L, nargs + nresults);
    }
    return nresults;
  }
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
  luaL_argcheck(L, size >= 0, 1, "size must be non-negative");
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
  lua_pushinteger(L, size);
  lua_setfield(L, tbl, "size");
  return 1;
}


/*
** ============================================================
** Built-in Option type support
** ============================================================
*/

/* Some(value) constructor - creates {__tag="Some", [1]=value} with metatable */
static int cangjie_some (lua_State *L) {
  lua_newtable(L);
  lua_pushliteral(L, "Some");
  lua_setfield(L, -2, "__tag");
  lua_pushvalue(L, 1);
  lua_rawseti(L, -2, 1);
  /* Set Option metatable */
  lua_getglobal(L, "__option_mt");
  if (!lua_isnil(L, -1))
    lua_setmetatable(L, -2);
  else
    lua_pop(L, 1);
  return 1;
}

/* Option.getOrThrow() - unwrap Some value or error on None */
static int cangjie_option_getOrThrow (lua_State *L) {
  lua_getfield(L, 1, "__tag");
  if (lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0) {
    lua_pop(L, 1);
    lua_rawgeti(L, 1, 1);
    return 1;
  }
  return luaL_error(L, "Option is None: cannot getOrThrow");
}

/* Option.isSome() */
static int cangjie_option_isSome (lua_State *L) {
  int result;
  lua_getfield(L, 1, "__tag");
  result = lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0;
  lua_pop(L, 1);
  lua_pushboolean(L, result);
  return 1;
}

/* Option.isNone() */
static int cangjie_option_isNone (lua_State *L) {
  int result;
  lua_getfield(L, 1, "__tag");
  result = lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "None") == 0;
  lua_pop(L, 1);
  lua_pushboolean(L, result);
  return 1;
}

/* Option.getOrDefault(defaultFn: () -> T) */
static int cangjie_option_getOrDefault (lua_State *L) {
  lua_getfield(L, 1, "__tag");
  if (lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), "Some") == 0) {
    lua_pop(L, 1);
    lua_rawgeti(L, 1, 1);
    return 1;
  }
  lua_pop(L, 1);
  /* Call the default-value function: defaultFn() */
  lua_pushvalue(L, 2);
  lua_call(L, 0, 1);
  return 1;
}

/* __index handler for Option values */
static int cangjie_option_index (lua_State *L) {
  const char *key = luaL_checkstring(L, 2);
  /* Check raw access first */
  lua_pushvalue(L, 2);
  lua_rawget(L, 1);
  if (!lua_isnil(L, -1)) return 1;
  lua_pop(L, 1);
  /* Method dispatch */
  if (strcmp(key, "getOrThrow") == 0) {
    lua_pushcfunction(L, cangjie_option_getOrThrow);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "isSome") == 0) {
    lua_pushcfunction(L, cangjie_option_isSome);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "isNone") == 0) {
    lua_pushcfunction(L, cangjie_option_isNone);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  if (strcmp(key, "getOrDefault") == 0) {
    lua_pushcfunction(L, cangjie_option_getOrDefault);
    lua_pushvalue(L, 1);
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  lua_pushnil(L);
  return 1;
}

/* __cangjie_coalesce(opt, default) - ?? operator runtime */
int luaB_coalesce (lua_State *L) {
  /* If opt is nil, return default */
  if (lua_isnil(L, 1)) {
    lua_pushvalue(L, 2);
    return 1;
  }
  /* If opt is a table with __tag */
  if (lua_istable(L, 1)) {
    lua_getfield(L, 1, "__tag");
    if (lua_isstring(L, -1)) {
      const char *tag = lua_tostring(L, -1);
      if (strcmp(tag, "None") == 0) {
        lua_pop(L, 1);
        lua_pushvalue(L, 2);  /* return default */
        return 1;
      }
      if (strcmp(tag, "Some") == 0) {
        lua_pop(L, 1);
        lua_rawgeti(L, 1, 1);  /* unwrap Some */
        return 1;
      }
    }
    lua_pop(L, 1);
  }
  /* Otherwise return opt as-is */
  lua_pushvalue(L, 1);
  return 1;
}

/*
** luaB_option_init(L) - Register built-in Some/None globals with metatables.
** Called during library initialization.
*/
int luaB_option_init (lua_State *L) {
  /* Create Option metatable */
  lua_newtable(L);  /* mt */
  lua_pushcfunction(L, cangjie_option_index);
  lua_setfield(L, -2, "__index");
  /* Store as global __option_mt */
  lua_pushvalue(L, -1);
  lua_setglobal(L, "__option_mt");

  /* Create Some function */
  lua_pushcfunction(L, cangjie_some);
  lua_setglobal(L, "Some");

  /* Create None value: {__tag="None"} with metatable */
  lua_newtable(L);
  lua_pushliteral(L, "None");
  lua_setfield(L, -2, "__tag");
  lua_pushvalue(L, -2);  /* push mt */
  lua_setmetatable(L, -2);
  lua_setglobal(L, "None");

  lua_pop(L, 1);  /* pop mt */
  return 0;
}


/*
** __cangjie_array_slice(arr_or_str, start, end, inclusive)
** For tables: returns a new 0-based array from arr[start] to arr[end-1]
** (exclusive) or arr[start] to arr[end] (inclusive).
** For strings: returns a substring.
*/
int luaB_array_slice (lua_State *L) {
  lua_Integer start, end, count;
  int inclusive;
  if (lua_type(L, 1) == LUA_TSTRING) {
    /* Delegate to string slice */
    return luaB_str_slice(L);
  }
  {
  lua_Integer i;
  luaL_checktype(L, 1, LUA_TTABLE);
  start = luaL_checkinteger(L, 2);
  end = luaL_checkinteger(L, 3);
  inclusive = lua_toboolean(L, 4);
  if (!inclusive) end--;
  count = end - start + 1;
  if (count < 0) count = 0;
  lua_newtable(L);
  for (i = 0; i < count; i++) {
    lua_geti(L, 1, start + i);
    lua_seti(L, -2, i);
  }
  lua_pushinteger(L, count);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, count);
  lua_setfield(L, -2, "size");
  return 1;
  }
}


/*
** __cangjie_array_slice_set(arr, start, end, inclusive, values)
** Assigns values from the 'values' array into arr[start..end].
*/
int luaB_array_slice_set (lua_State *L) {
  lua_Integer start, end, i, count;
  int inclusive;
  luaL_checktype(L, 1, LUA_TTABLE);
  start = luaL_checkinteger(L, 2);
  end = luaL_checkinteger(L, 3);
  inclusive = lua_toboolean(L, 4);
  luaL_checktype(L, 5, LUA_TTABLE);
  if (!inclusive) end--;
  count = end - start + 1;
  if (count < 0) count = 0;
  for (i = 0; i < count; i++) {
    lua_geti(L, 5, i);
    lua_seti(L, 1, start + i);
  }
  return 0;
}


/*
** ============================================================
** UTF-8 helpers (reused from lutf8lib.c)
** ============================================================
*/

#define MAXUNICODE_CJ	0x10FFFFu
#define iscont_cj(c)	(((c) & 0xC0) == 0x80)

/*
** Decode one UTF-8 sequence, returning NULL if byte sequence is invalid.
** The 'limits' array stores the minimum code point for each sequence length,
** to reject overlong encodings: [0]=force error for no continuation bytes,
** [1]=2-byte min 0x80, [2]=3-byte min 0x800, [3]=4-byte min 0x10000,
** [4]=5-byte min 0x200000, [5]=6-byte min 0x4000000.
*/
static const char *utf8_decode_cj (const char *s, l_uint32 *val) {
  static const l_uint32 limits[] =
        {~(l_uint32)0, 0x80, 0x800, 0x10000u, 0x200000u, 0x4000000u};
  unsigned int c = (unsigned char)s[0];
  l_uint32 res = 0;
  if (c < 0x80)
    res = c;
  else {
    int count = 0;
    for (; c & 0x40; c <<= 1) {
      unsigned int cc = (unsigned char)s[++count];
      if (!iscont_cj(cc))
        return NULL;
      res = (res << 6) | (cc & 0x3F);
    }
    res |= ((l_uint32)(c & 0x7F) << (count * 5));
    if (count > 5 || res > 0x7FFFFFFFu || res < limits[count])
      return NULL;
    s += count;
  }
  /* check for invalid code points: surrogates */
  if (res > MAXUNICODE_CJ || (0xD800u <= res && res <= 0xDFFFu))
    return NULL;
  if (val) *val = res;
  return s + 1;
}


/*
** Count UTF-8 characters in a string of byte length 'len'.
** Returns character count, or -1 if invalid UTF-8.
*/
static lua_Integer utf8_charcount (const char *s, size_t len) {
  lua_Integer n = 0;
  size_t pos = 0;
  while (pos < len) {
    const char *next = utf8_decode_cj(s + pos, NULL);
    if (next == NULL) return -1;  /* invalid UTF-8 */
    pos = (size_t)(next - s);
    n++;
  }
  return n;
}


/*
** Get byte offset of the n-th (0-based) UTF-8 character.
** Returns the byte offset, or -1 if out of range.
*/
static lua_Integer utf8_byte_offset (const char *s, size_t len,
                                     lua_Integer charIdx) {
  lua_Integer n = 0;
  size_t pos = 0;
  if (charIdx < 0) return -1;
  while (pos < len) {
    if (n == charIdx) return (lua_Integer)pos;
    {
    const char *next = utf8_decode_cj(s + pos, NULL);
    if (next == NULL) return -1;
    pos = (size_t)(next - s);
    n++;
    }
  }
  if (n == charIdx) return (lua_Integer)pos;  /* one past the end */
  return -1;
}


/*
** ============================================================
** Cangjie string member methods (built-in)
** ============================================================
*/

/* bound method helper: wraps (cfunc, self) into a closure that
   calls cfunc with self as first argument */
static int str_bound_call (lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  lua_pushvalue(L, lua_upvalueindex(1));  /* push cfunc */
  lua_pushvalue(L, lua_upvalueindex(2));  /* push self (string) */
  for (i = 1; i <= nargs; i++)
    lua_pushvalue(L, i);  /* push call arguments */
  lua_call(L, nargs + 1, LUA_MULTRET);
  return lua_gettop(L) - nargs;
}

/* s:isEmpty() -> Bool */
static int str_isEmpty (lua_State *L) {
  size_t len;
  luaL_checklstring(L, 1, &len);
  lua_pushboolean(L, len == 0);
  return 1;
}

/* s:contains(sub) -> Bool */
static int str_contains (lua_State *L) {
  size_t slen, sublen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *sub = luaL_checklstring(L, 2, &sublen);
  if (sublen == 0) { lua_pushboolean(L, 1); return 1; }
  lua_pushboolean(L, strstr(s, sub) != NULL);
  return 1;
}

/* s:startsWith(prefix) -> Bool */
static int str_startsWith (lua_State *L) {
  size_t slen, plen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *prefix = luaL_checklstring(L, 2, &plen);
  lua_pushboolean(L, plen <= slen && memcmp(s, prefix, plen) == 0);
  return 1;
}

/* s:endsWith(suffix) -> Bool */
static int str_endsWith (lua_State *L) {
  size_t slen, suflen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *suffix = luaL_checklstring(L, 2, &suflen);
  lua_pushboolean(L, suflen <= slen &&
                  memcmp(s + slen - suflen, suffix, suflen) == 0);
  return 1;
}

/* s:replace(old, new) -> String */
static int str_replace_cj (lua_State *L) {
  size_t slen, oldlen, newlen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *old = luaL_checklstring(L, 2, &oldlen);
  const char *newstr = luaL_checklstring(L, 3, &newlen);
  luaL_Buffer b;
  const char *p;
  luaL_buffinit(L, &b);
  if (oldlen == 0) {
    /* empty old string: just return original */
    lua_pushvalue(L, 1);
    return 1;
  }
  while ((p = strstr(s, old)) != NULL) {
    luaL_addlstring(&b, s, (size_t)(p - s));
    luaL_addlstring(&b, newstr, newlen);
    s = p + oldlen;
  }
  luaL_addstring(&b, s);
  luaL_pushresult(&b);
  return 1;
}

/*
** s:split(sep) -> Array<String> (0-based table with .size)
** Note: For invalid UTF-8 bytes (when sep is empty), we fall back to
** single-byte handling to gracefully handle Lua's arbitrary byte strings.
*/
static int str_split_cj (lua_State *L) {
  size_t slen, seplen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *sep = luaL_checklstring(L, 2, &seplen);
  int idx = 0;
  const char *p;
  lua_newtable(L);
  if (seplen == 0) {
    /* split into UTF-8 characters */
    size_t pos = 0;
    while (pos < slen) {
      const char *next = utf8_decode_cj(s + pos, NULL);
      size_t clen;
      if (next == NULL) {
        /* fallback: single byte */
        next = s + pos + 1;
      }
      clen = (size_t)(next - (s + pos));
      lua_pushlstring(L, s + pos, clen);
      lua_rawseti(L, -2, idx++);
      pos = (size_t)(next - s);
    }
  } else {
    while ((p = strstr(s, sep)) != NULL) {
      lua_pushlstring(L, s, (size_t)(p - s));
      lua_rawseti(L, -2, idx++);
      s = p + seplen;
    }
    lua_pushstring(L, s);
    lua_rawseti(L, -2, idx++);
  }
  lua_pushinteger(L, idx);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, idx);
  lua_setfield(L, -2, "size");
  return 1;
}

/* s:trim() -> String (remove leading/trailing whitespace) */
static int str_trim_cj (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  const char *start = s;
  const char *end = s + len;
  while (start < end && (*start == ' ' || *start == '\t' ||
         *start == '\n' || *start == '\r'))
    start++;
  while (end > start && (*(end-1) == ' ' || *(end-1) == '\t' ||
         *(end-1) == '\n' || *(end-1) == '\r'))
    end--;
  lua_pushlstring(L, start, (size_t)(end - start));
  return 1;
}

/* s:trimStart() -> String */
static int str_trimStart_cj (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  const char *start = s;
  const char *end = s + len;
  while (start < end && (*start == ' ' || *start == '\t' ||
         *start == '\n' || *start == '\r'))
    start++;
  lua_pushlstring(L, start, (size_t)(end - start));
  return 1;
}

/* s:trimEnd() -> String */
static int str_trimEnd_cj (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  const char *end = s + len;
  while (end > s && (*(end-1) == ' ' || *(end-1) == '\t' ||
         *(end-1) == '\n' || *(end-1) == '\r'))
    end--;
  lua_pushlstring(L, s, (size_t)(end - s));
  return 1;
}

/* s:toAsciiUpper() -> String */
static int str_toAsciiUpper (lua_State *L) {
  size_t len, i;
  const char *s = luaL_checklstring(L, 1, &len);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  for (i = 0; i < len; i++) {
    char c = s[i];
    if (c >= 'a' && c <= 'z') c = (char)(c - 32);
    luaL_addchar(&b, c);
  }
  luaL_pushresult(&b);
  return 1;
}

/* s:toAsciiLower() -> String */
static int str_toAsciiLower (lua_State *L) {
  size_t len, i;
  const char *s = luaL_checklstring(L, 1, &len);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  for (i = 0; i < len; i++) {
    char c = s[i];
    if (c >= 'A' && c <= 'Z') c = (char)(c + 32);
    luaL_addchar(&b, c);
  }
  luaL_pushresult(&b);
  return 1;
}

/* s:toArray() -> Array<Byte> (UTF-8 byte array, 0-based) */
static int str_toArray_cj (lua_State *L) {
  size_t len, i;
  const char *s = luaL_checklstring(L, 1, &len);
  lua_newtable(L);
  for (i = 0; i < len; i++) {
    lua_pushinteger(L, (lua_Integer)((unsigned char)s[i]));
    lua_rawseti(L, -2, (lua_Integer)i);
  }
  lua_pushinteger(L, (lua_Integer)len);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, (lua_Integer)len);
  lua_setfield(L, -2, "size");
  return 1;
}

/*
** s:toRuneArray() -> Array<Rune> (UTF-8 character array, 0-based)
** Invalid UTF-8 bytes are treated as single-byte characters to gracefully
** handle Lua's arbitrary byte strings.
*/
static int str_toRuneArray_cj (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  int idx = 0;
  size_t pos = 0;
  lua_newtable(L);
  while (pos < len) {
    const char *next = utf8_decode_cj(s + pos, NULL);
    size_t clen;
    if (next == NULL) {
      next = s + pos + 1;
    }
    clen = (size_t)(next - (s + pos));
    lua_pushlstring(L, s + pos, clen);
    lua_rawseti(L, -2, idx++);
    pos = (size_t)(next - s);
  }
  lua_pushinteger(L, idx);
  lua_setfield(L, -2, "__n");
  lua_pushinteger(L, idx);
  lua_setfield(L, -2, "size");
  return 1;
}

/*
** s:indexOf(sub [, fromIndex]) -> Int64 or -1
** Returns character position. Invalid UTF-8 bytes are counted as single
** characters for position calculation.
*/
static int str_indexOf_cj (lua_State *L) {
  size_t slen, sublen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *sub = luaL_checklstring(L, 2, &sublen);
  lua_Integer fromCharIdx = luaL_optinteger(L, 3, 0);
  lua_Integer byteOff, charIdx;
  const char *found;
  size_t pos;
  if (fromCharIdx < 0) fromCharIdx = 0;
  byteOff = utf8_byte_offset(s, slen, fromCharIdx);
  if (byteOff < 0) {
    lua_pushinteger(L, -1);
    return 1;
  }
  found = strstr(s + byteOff, sub);
  if (found == NULL) {
    lua_pushinteger(L, -1);
    return 1;
  }
  /* Convert byte position to char index */
  charIdx = 0;
  pos = 0;
  while (pos < (size_t)(found - s)) {
    const char *next = utf8_decode_cj(s + pos, NULL);
    if (next == NULL) { pos++; charIdx++; continue; }
    pos = (size_t)(next - s);
    charIdx++;
  }
  lua_pushinteger(L, charIdx);
  return 1;
}

/*
** s:lastIndexOf(sub [, fromIndex]) -> Int64 or -1
** Returns character position. Invalid UTF-8 bytes are counted as single
** characters for position calculation.
*/
static int str_lastIndexOf_cj (lua_State *L) {
  size_t slen, sublen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *sub = luaL_checklstring(L, 2, &sublen);
  lua_Integer charCount = utf8_charcount(s, slen);
  lua_Integer fromCharIdx = luaL_optinteger(L, 3, charCount);
  lua_Integer byteOff, lastBytePos, charIdx;
  size_t pos;
  const char *search_end;
  if (charCount < 0) charCount = 0;
  if (fromCharIdx > charCount) fromCharIdx = charCount;
  if (fromCharIdx < 0) fromCharIdx = 0;
  byteOff = utf8_byte_offset(s, slen, fromCharIdx);
  if (byteOff < 0) byteOff = (lua_Integer)slen;
  /* Search backwards from byteOff */
  search_end = s + byteOff;
  lastBytePos = -1;
  {
    const char *p = s;
    while (p <= search_end && (size_t)(p - s) + sublen <= slen) {
      if (memcmp(p, sub, sublen) == 0) {
        lastBytePos = (lua_Integer)(p - s);
      }
      p++;
    }
  }
  if (lastBytePos < 0) {
    lua_pushinteger(L, -1);
    return 1;
  }
  /* Convert byte position to char index */
  charIdx = 0;
  pos = 0;
  while ((lua_Integer)pos < lastBytePos) {
    const char *next = utf8_decode_cj(s + pos, NULL);
    if (next == NULL) { pos++; charIdx++; continue; }
    pos = (size_t)(next - s);
    charIdx++;
  }
  lua_pushinteger(L, charIdx);
  return 1;
}

/* s:count(sub) -> Int64 */
static int str_count_cj (lua_State *L) {
  size_t slen, sublen;
  const char *s = luaL_checklstring(L, 1, &slen);
  const char *sub = luaL_checklstring(L, 2, &sublen);
  lua_Integer count = 0;
  const char *p;
  if (sublen == 0) {
    /* count of empty string: utf8 char count + 1 */
    lua_Integer cc = utf8_charcount(s, slen);
    lua_pushinteger(L, cc < 0 ? 1 : cc + 1);
    return 1;
  }
  p = s;
  while ((p = strstr(p, sub)) != NULL) {
    count++;
    p += sublen;
  }
  lua_pushinteger(L, count);
  return 1;
}

/* String.fromUtf8(byteArray) -> String */
static int str_fromUtf8 (lua_State *L) {
  luaL_Buffer b;
  lua_Integer n, i;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "size");
  n = lua_isnil(L, -1) ? 0 : lua_tointeger(L, -1);
  lua_pop(L, 1);
  if (n <= 0) {
    lua_getfield(L, 1, "__n");
    n = lua_isnil(L, -1) ? 0 : lua_tointeger(L, -1);
    lua_pop(L, 1);
  }
  luaL_buffinit(L, &b);
  for (i = 0; i < n; i++) {
    lua_Integer byteVal;
    lua_rawgeti(L, 1, i);
    byteVal = lua_tointeger(L, -1);
    lua_pop(L, 1);
    if (byteVal < 0 || byteVal > 255) {
      return luaL_error(L, "byte value %I out of range [0, 255] at index %I",
                        (long long)byteVal, (long long)i);
    }
    luaL_addchar(&b, (char)(unsigned char)byteVal);
  }
  luaL_pushresult(&b);
  return 1;
}


/* Method dispatch table for string methods */
typedef struct {
  const char *name;
  lua_CFunction func;
} StrMethod;

static const StrMethod str_methods[] = {
  {"isEmpty", str_isEmpty},
  {"contains", str_contains},
  {"startsWith", str_startsWith},
  {"endsWith", str_endsWith},
  {"replace", str_replace_cj},
  {"split", str_split_cj},
  {"trim", str_trim_cj},
  {"trimStart", str_trimStart_cj},
  {"trimEnd", str_trimEnd_cj},
  {"toAsciiUpper", str_toAsciiUpper},
  {"toAsciiLower", str_toAsciiLower},
  {"toArray", str_toArray_cj},
  {"toRuneArray", str_toRuneArray_cj},
  {"indexOf", str_indexOf_cj},
  {"lastIndexOf", str_lastIndexOf_cj},
  {"count", str_count_cj},
  {NULL, NULL}
};


/*
** ============================================================
** Cangjie string indexing and slicing support (UTF-8 aware)
** ============================================================
*/

/*
** __cangjie_str_index(s, key)
** Used as __index metamethod for strings.
** If key is an integer, return the UTF-8 character (Rune) at that
** 0-based character position.
** If key is "size", return the UTF-8 character count.
** If key is a built-in method name, return a bound method.
** Otherwise, delegate to the string library table.
*/
int luaB_str_index (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  if (lua_type(L, 2) == LUA_TNUMBER) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer charCount = utf8_charcount(s, len);
    lua_Integer byteOff;
    const char *next;
    size_t clen;
    if (charCount < 0) charCount = (lua_Integer)len;  /* fallback */
    if (idx < 0 || idx >= charCount) {
      return luaL_error(L, "string index %I out of range (size %I)",
                        (long long)idx, (long long)charCount);
    }
    byteOff = utf8_byte_offset(s, len, idx);
    if (byteOff < 0 || (size_t)byteOff >= len) {
      return luaL_error(L, "string index %I out of range (size %I)",
                        (long long)idx, (long long)charCount);
    }
    next = utf8_decode_cj(s + byteOff, NULL);
    if (next == NULL) next = s + byteOff + 1;
    clen = (size_t)(next - (s + byteOff));
    lua_pushlstring(L, s + byteOff, clen);
    return 1;
  }
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0) {
      lua_Integer charCount = utf8_charcount(s, len);
      if (charCount < 0) charCount = (lua_Integer)len;
      lua_pushinteger(L, charCount);
      return 1;
    }
    /* Check built-in string methods */
    {
      const StrMethod *m;
      for (m = str_methods; m->name != NULL; m++) {
        if (strcmp(key, m->name) == 0) {
          /* Return a bound method: closure(cfunc, self) */
          lua_pushcfunction(L, m->func);
          lua_pushvalue(L, 1);  /* push self string */
          lua_pushcclosure(L, str_bound_call, 2);
          return 1;
        }
      }
    }
    /* Delegate to string library table (upvalue 1) */
    lua_pushvalue(L, lua_upvalueindex(1));  /* push string lib table */
    lua_pushvalue(L, 2);                    /* push key */
    lua_gettable(L, -2);                    /* get string[key] */
    return 1;
  }
  lua_pushnil(L);
  return 1;
}


/*
** __cangjie_str_newindex(s, key, value)
** Used as __newindex metamethod for strings.
** Strings are immutable in Cangjie/Lua.
*/
int luaB_str_newindex (lua_State *L) {
  return luaL_error(L,
      "strings are immutable; use string concatenation to build new strings");
}


/*
** __cangjie_str_slice(s, start, end, inclusive)
** Returns a substring from s[start] to s[end-1] (exclusive)
** or s[start] to s[end] (inclusive).  0-based character indices (UTF-8).
*/
int luaB_str_slice (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  lua_Integer start = luaL_checkinteger(L, 2);
  lua_Integer end = luaL_checkinteger(L, 3);
  int inclusive = lua_toboolean(L, 4);
  lua_Integer charCount = utf8_charcount(s, len);
  lua_Integer startByte, endByte;
  if (charCount < 0) charCount = (lua_Integer)len;
  if (!inclusive) end--;
  if (start < 0) start = 0;
  if (end >= charCount) end = charCount - 1;
  if (end < start) {
    lua_pushliteral(L, "");
    return 1;
  }
  startByte = utf8_byte_offset(s, len, start);
  endByte = utf8_byte_offset(s, len, end + 1);
  if (startByte < 0) startByte = 0;
  if (endByte < 0) endByte = (lua_Integer)len;
  if (endByte <= startByte) {
    lua_pushliteral(L, "");
  }
  else {
    lua_pushlstring(L, s + startByte, (size_t)(endByte - startByte));
  }
  return 1;
}


/*
** __cangjie_byte_array_from_string(s)
** Convert string to Array<Byte> (same as s:toArray())
*/
int luaB_byte_array_from_string (lua_State *L) {
  return str_toArray_cj(L);
}

/*
** __cangjie_string_from_byte_array(arr)
** Convert Array<Byte> to String (UTF-8)
*/
int luaB_string_from_byte_array (lua_State *L) {
  return str_fromUtf8(L);
}

/*
** __cangjie_str_len(s)
** Return UTF-8 character count for __len metamethod.
*/
static int luaB_str_len_utf8 (lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  lua_Integer charCount = utf8_charcount(s, len);
  if (charCount < 0) charCount = (lua_Integer)len;
  lua_pushinteger(L, charCount);
  return 1;
}


/*
** Set up string metatable for Cangjie-style indexing.
** Called during interpreter initialization.
*/
int luaB_setup_string_meta (lua_State *L) {
  lua_pushliteral(L, "");           /* push any string */
  if (!lua_getmetatable(L, -1)) {   /* get its metatable */
    lua_pop(L, 1);
    return 0;
  }
  /* Stack: "" metatable */
  /* Set __index to luaB_str_index with string lib as upvalue */
  lua_getfield(L, -1, "__index");   /* get current __index (= string lib) */
  lua_pushcclosure(L, luaB_str_index, 1);  /* create closure with upvalue */
  lua_setfield(L, -2, "__index");   /* metatable.__index = closure */
  /* Set __newindex */
  lua_pushcfunction(L, luaB_str_newindex);
  lua_setfield(L, -2, "__newindex");
  /* Set __len to return UTF-8 character count */
  lua_pushcfunction(L, luaB_str_len_utf8);
  lua_setfield(L, -2, "__len");

  /* Register String.fromUtf8 as a global helper */
  lua_pushcfunction(L, str_fromUtf8);
  lua_setglobal(L, "__cangjie_string_from_byte_array");

  lua_pop(L, 2);  /* pop metatable and "" */
  return 0;
}
