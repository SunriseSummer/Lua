/*
** $Id: lbaselib.c $
** Basic library
** See Copyright Notice in lua.h
*/

#define lbaselib_c
#define LUA_LIB

#include "lprefix.h"


#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "llimits.h"


static int luaB_print (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  int i;
  for (i = 1; i <= n; i++) {  /* for each argument */
    size_t l;
    const char *s = luaL_tolstring(L, i, &l);  /* convert it to string */
    if (i > 1)  /* not the first element? */
      lua_writestring("\t", 1);  /* add a tab before it */
    lua_writestring(s, l);  /* print it */
    lua_pop(L, 1);  /* pop result */
  }
  return 0;
}


static int luaB_println (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  int i;
  for (i = 1; i <= n; i++) {  /* for each argument */
    size_t l;
    const char *s = luaL_tolstring(L, i, &l);  /* convert it to string */
    if (i > 1)  /* not the first element? */
      lua_writestring("\t", 1);  /* add a tab before it */
    lua_writestring(s, l);  /* print it */
    lua_pop(L, 1);  /* pop result */
  }
  lua_writeline();
  return 0;
}


/*
** __cangjie_setup_class(cls) - Set up a class table so that calling
** cls(args) creates a new instance (via __call metamethod).
** The __call creates a new table, sets cls as its metatable,
** calls cls.init if it exists, and returns the instance.
** Also sets up a custom __index that auto-binds methods (wrapping
** function values with a closure that passes self as first arg).
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
** return a bound method; otherwise return the raw value. */
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
  /* Look up in the class table */
  lua_pushvalue(L, 2);  /* push key */
  lua_gettable(L, lua_upvalueindex(1));  /* get cls[key] */
  if (lua_isfunction(L, -1)) {
    /* It's a method - create a bound method closure */
    /* push function and obj as upvalues */
    lua_pushvalue(L, -1);  /* function */
    lua_pushvalue(L, 1);   /* obj (self) */
    lua_pushcclosure(L, cangjie_bound_method, 2);
    return 1;
  }
  return 1;  /* return the value as-is (nil or other) */
}

static int cangjie_call_handler (lua_State *L) {
  /* Arguments: cls, arg1, arg2, ... (cls is first arg via __call) */
  int nargs = lua_gettop(L) - 1;  /* number of constructor args (excluding cls) */
  int i;
  lua_newtable(L);              /* create new instance: obj = {} */
  /* stack: [cls, arg1, ..., argN, obj] */
  int obj = lua_gettop(L);
  /* Set up metatable for the instance with custom __index */
  lua_newtable(L);              /* instance metatable */
  lua_pushvalue(L, 1);          /* push cls as upvalue */
  lua_pushcclosure(L, cangjie_index_handler, 1);
  lua_setfield(L, -2, "__index");
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
  }
  lua_pushvalue(L, obj);        /* return obj */
  return 1;
}

static int luaB_setup_class (lua_State *L) {
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

static int luaB_extend_type (lua_State *L) {
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
static int luaB_copy_to_type (lua_State *L) {
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
** Creates a warning with all given arguments.
** Check first for errors; otherwise an error may interrupt
** the composition of a warning, leaving it unfinished.
*/
static int luaB_warn (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  int i;
  luaL_checkstring(L, 1);  /* at least one argument */
  for (i = 2; i <= n; i++)
    luaL_checkstring(L, i);  /* make sure all arguments are strings */
  for (i = 1; i < n; i++)  /* compose warning */
    lua_warning(L, lua_tostring(L, i), 1);
  lua_warning(L, lua_tostring(L, n), 0);  /* close warning */
  return 0;
}


#define SPACECHARS	" \f\n\r\t\v"

static const char *b_str2int (const char *s, unsigned base, lua_Integer *pn) {
  lua_Unsigned n = 0;
  int neg = 0;
  s += strspn(s, SPACECHARS);  /* skip initial spaces */
  if (*s == '-') { s++; neg = 1; }  /* handle sign */
  else if (*s == '+') s++;
  if (!isalnum(cast_uchar(*s)))  /* no digit? */
    return NULL;
  do {
    unsigned digit = cast_uint(isdigit(cast_uchar(*s))
                               ? *s - '0'
                               : (toupper(cast_uchar(*s)) - 'A') + 10);
    if (digit >= base) return NULL;  /* invalid numeral */
    n = n * base + digit;
    s++;
  } while (isalnum(cast_uchar(*s)));
  s += strspn(s, SPACECHARS);  /* skip trailing spaces */
  *pn = (lua_Integer)((neg) ? (0u - n) : n);
  return s;
}


static int luaB_tonumber (lua_State *L) {
  if (lua_isnoneornil(L, 2)) {  /* standard conversion? */
    if (lua_type(L, 1) == LUA_TNUMBER) {  /* already a number? */
      lua_settop(L, 1);  /* yes; return it */
      return 1;
    }
    else {
      size_t l;
      const char *s = lua_tolstring(L, 1, &l);
      if (s != NULL && lua_stringtonumber(L, s) == l + 1)
        return 1;  /* successful conversion to number */
      /* else not a number */
      luaL_checkany(L, 1);  /* (but there must be some parameter) */
    }
  }
  else {
    size_t l;
    const char *s;
    lua_Integer n = 0;  /* to avoid warnings */
    lua_Integer base = luaL_checkinteger(L, 2);
    luaL_checktype(L, 1, LUA_TSTRING);  /* no numbers as strings */
    s = lua_tolstring(L, 1, &l);
    luaL_argcheck(L, 2 <= base && base <= 36, 2, "base out of range");
    if (b_str2int(s, cast_uint(base), &n) == s + l) {
      lua_pushinteger(L, n);
      return 1;
    }  /* else not a number */
  }  /* else not a number */
  luaL_pushfail(L);  /* not a number */
  return 1;
}


static int luaB_error (lua_State *L) {
  int level = (int)luaL_optinteger(L, 2, 1);
  lua_settop(L, 1);
  if (lua_type(L, 1) == LUA_TSTRING && level > 0) {
    luaL_where(L, level);   /* add extra information */
    lua_pushvalue(L, 1);
    lua_concat(L, 2);
  }
  return lua_error(L);
}


static int luaB_getmetatable (lua_State *L) {
  luaL_checkany(L, 1);
  if (!lua_getmetatable(L, 1)) {
    lua_pushnil(L);
    return 1;  /* no metatable */
  }
  luaL_getmetafield(L, 1, "__metatable");
  return 1;  /* returns either __metatable field (if present) or metatable */
}


static int luaB_setmetatable (lua_State *L) {
  int t = lua_type(L, 2);
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_argexpected(L, t == LUA_TNIL || t == LUA_TTABLE, 2, "nil or table");
  if (l_unlikely(luaL_getmetafield(L, 1, "__metatable") != LUA_TNIL))
    return luaL_error(L, "cannot change a protected metatable");
  lua_settop(L, 2);
  lua_setmetatable(L, 1);
  return 1;
}


static int luaB_rawequal (lua_State *L) {
  luaL_checkany(L, 1);
  luaL_checkany(L, 2);
  lua_pushboolean(L, lua_rawequal(L, 1, 2));
  return 1;
}


static int luaB_rawlen (lua_State *L) {
  int t = lua_type(L, 1);
  luaL_argexpected(L, t == LUA_TTABLE || t == LUA_TSTRING, 1,
                      "table or string");
  lua_pushinteger(L, l_castU2S(lua_rawlen(L, 1)));
  return 1;
}


static int luaB_rawget (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checkany(L, 2);
  lua_settop(L, 2);
  lua_rawget(L, 1);
  return 1;
}

static int luaB_rawset (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checkany(L, 2);
  luaL_checkany(L, 3);
  lua_settop(L, 3);
  lua_rawset(L, 1);
  return 1;
}


static int pushmode (lua_State *L, int oldmode) {
  if (oldmode == -1)
    luaL_pushfail(L);  /* invalid call to 'lua_gc' */
  else
    lua_pushstring(L, (oldmode == LUA_GCINC) ? "incremental"
                                             : "generational");
  return 1;
}


/*
** check whether call to 'lua_gc' was valid (not inside a finalizer)
*/
#define checkvalres(res) { if (res == -1) break; }

static int luaB_collectgarbage (lua_State *L) {
  static const char *const opts[] = {"stop", "restart", "collect",
    "count", "step", "isrunning", "generational", "incremental",
    "param", NULL};
  static const char optsnum[] = {LUA_GCSTOP, LUA_GCRESTART, LUA_GCCOLLECT,
    LUA_GCCOUNT, LUA_GCSTEP, LUA_GCISRUNNING, LUA_GCGEN, LUA_GCINC,
    LUA_GCPARAM};
  int o = optsnum[luaL_checkoption(L, 1, "collect", opts)];
  switch (o) {
    case LUA_GCCOUNT: {
      int k = lua_gc(L, o);
      int b = lua_gc(L, LUA_GCCOUNTB);
      checkvalres(k);
      lua_pushnumber(L, (lua_Number)k + ((lua_Number)b/1024));
      return 1;
    }
    case LUA_GCSTEP: {
      lua_Integer n = luaL_optinteger(L, 2, 0);
      int res = lua_gc(L, o, cast_sizet(n));
      checkvalres(res);
      lua_pushboolean(L, res);
      return 1;
    }
    case LUA_GCISRUNNING: {
      int res = lua_gc(L, o);
      checkvalres(res);
      lua_pushboolean(L, res);
      return 1;
    }
    case LUA_GCGEN: {
      return pushmode(L, lua_gc(L, o));
    }
    case LUA_GCINC: {
      return pushmode(L, lua_gc(L, o));
    }
    case LUA_GCPARAM: {
      static const char *const params[] = {
        "minormul", "majorminor", "minormajor",
        "pause", "stepmul", "stepsize", NULL};
      static const char pnum[] = {
        LUA_GCPMINORMUL, LUA_GCPMAJORMINOR, LUA_GCPMINORMAJOR,
        LUA_GCPPAUSE, LUA_GCPSTEPMUL, LUA_GCPSTEPSIZE};
      int p = pnum[luaL_checkoption(L, 2, NULL, params)];
      lua_Integer value = luaL_optinteger(L, 3, -1);
      lua_pushinteger(L, lua_gc(L, o, p, (int)value));
      return 1;
    }
    default: {
      int res = lua_gc(L, o);
      checkvalres(res);
      lua_pushinteger(L, res);
      return 1;
    }
  }
  luaL_pushfail(L);  /* invalid call (inside a finalizer) */
  return 1;
}


static int luaB_type (lua_State *L) {
  int t = lua_type(L, 1);
  luaL_argcheck(L, t != LUA_TNONE, 1, "value expected");
  lua_pushstring(L, lua_typename(L, t));
  return 1;
}


static int luaB_next (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_settop(L, 2);  /* create a 2nd argument if there isn't one */
  if (lua_next(L, 1))
    return 2;
  else {
    lua_pushnil(L);
    return 1;
  }
}


static int pairscont (lua_State *L, int status, lua_KContext k) {
  (void)L; (void)status; (void)k;  /* unused */
  return 4;  /* __pairs did all the work, just return its results */
}

static int luaB_pairs (lua_State *L) {
  luaL_checkany(L, 1);
  if (luaL_getmetafield(L, 1, "__pairs") == LUA_TNIL) {  /* no metamethod? */
    lua_pushcfunction(L, luaB_next);  /* will return generator and */
    lua_pushvalue(L, 1);  /* state */
    lua_pushnil(L);  /* initial value */
    lua_pushnil(L);  /* to-be-closed object */
  }
  else {
    lua_pushvalue(L, 1);  /* argument 'self' to metamethod */
    lua_callk(L, 1, 4, 0, pairscont);  /* get 4 values from metamethod */
  }
  return 4;
}


/*
** Traversal function for 'ipairs'
*/
static int ipairsaux (lua_State *L) {
  lua_Integer i = luaL_checkinteger(L, 2);
  i = luaL_intop(+, i, 1);
  lua_pushinteger(L, i);
  return (lua_geti(L, 1, i) == LUA_TNIL) ? 1 : 2;
}


/*
** 'ipairs' function. Returns 'ipairsaux', given "table", 0.
** (The given "table" may not be a table.)
*/
static int luaB_ipairs (lua_State *L) {
  luaL_checkany(L, 1);
  lua_pushcfunction(L, ipairsaux);  /* iteration function */
  lua_pushvalue(L, 1);  /* state */
  lua_pushinteger(L, 0);  /* initial value */
  return 3;
}


static int load_aux (lua_State *L, int status, int envidx) {
  if (l_likely(status == LUA_OK)) {
    if (envidx != 0) {  /* 'env' parameter? */
      lua_pushvalue(L, envidx);  /* environment for loaded function */
      if (!lua_setupvalue(L, -2, 1))  /* set it as 1st upvalue */
        lua_pop(L, 1);  /* remove 'env' if not used by previous call */
    }
    return 1;
  }
  else {  /* error (message is on top of the stack) */
    luaL_pushfail(L);
    lua_insert(L, -2);  /* put before error message */
    return 2;  /* return fail plus error message */
  }
}


static const char *getMode (lua_State *L, int idx) {
  const char *mode = luaL_optstring(L, idx, "bt");
  if (strchr(mode, 'B') != NULL)  /* Lua code cannot use fixed buffers */
    luaL_argerror(L, idx, "invalid mode");
  return mode;
}


static int luaB_loadfile (lua_State *L) {
  const char *fname = luaL_optstring(L, 1, NULL);
  const char *mode = getMode(L, 2);
  int env = (!lua_isnone(L, 3) ? 3 : 0);  /* 'env' index or 0 if no 'env' */
  int status = luaL_loadfilex(L, fname, mode);
  return load_aux(L, status, env);
}


/*
** {======================================================
** Generic Read function
** =======================================================
*/


/*
** reserved slot, above all arguments, to hold a copy of the returned
** string to avoid it being collected while parsed. 'load' has four
** optional arguments (chunk, source name, mode, and environment).
*/
#define RESERVEDSLOT	5


/*
** Reader for generic 'load' function: 'lua_load' uses the
** stack for internal stuff, so the reader cannot change the
** stack top. Instead, it keeps its resulting string in a
** reserved slot inside the stack.
*/
static const char *generic_reader (lua_State *L, void *ud, size_t *size) {
  (void)(ud);  /* not used */
  luaL_checkstack(L, 2, "too many nested functions");
  lua_pushvalue(L, 1);  /* get function */
  lua_call(L, 0, 1);  /* call it */
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);  /* pop result */
    *size = 0;
    return NULL;
  }
  else if (l_unlikely(!lua_isstring(L, -1)))
    luaL_error(L, "reader function must return a string");
  lua_replace(L, RESERVEDSLOT);  /* save string in reserved slot */
  return lua_tolstring(L, RESERVEDSLOT, size);
}


static int luaB_load (lua_State *L) {
  int status;
  size_t l;
  const char *s = lua_tolstring(L, 1, &l);
  const char *mode = getMode(L, 3);
  int env = (!lua_isnone(L, 4) ? 4 : 0);  /* 'env' index or 0 if no 'env' */
  if (s != NULL) {  /* loading a string? */
    const char *chunkname = luaL_optstring(L, 2, s);
    status = luaL_loadbufferx(L, s, l, chunkname, mode);
  }
  else {  /* loading from a reader function */
    const char *chunkname = luaL_optstring(L, 2, "=(load)");
    luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_settop(L, RESERVEDSLOT);  /* create reserved slot */
    status = lua_load(L, generic_reader, NULL, chunkname, mode);
  }
  return load_aux(L, status, env);
}

/* }====================================================== */


static int dofilecont (lua_State *L, int d1, lua_KContext d2) {
  (void)d1;  (void)d2;  /* only to match 'lua_Kfunction' prototype */
  return lua_gettop(L) - 1;
}


static int luaB_dofile (lua_State *L) {
  const char *fname = luaL_optstring(L, 1, NULL);
  lua_settop(L, 1);
  if (l_unlikely(luaL_loadfile(L, fname) != LUA_OK))
    return lua_error(L);
  lua_callk(L, 0, LUA_MULTRET, 0, dofilecont);
  return dofilecont(L, 0, 0);
}


static int luaB_assert (lua_State *L) {
  if (l_likely(lua_toboolean(L, 1)))  /* condition is true? */
    return lua_gettop(L);  /* return all arguments */
  else {  /* error */
    luaL_checkany(L, 1);  /* there must be a condition */
    lua_remove(L, 1);  /* remove it */
    lua_pushliteral(L, "assertion failed!");  /* default message */
    lua_settop(L, 1);  /* leave only message (default if no other one) */
    return luaB_error(L);  /* call 'error' */
  }
}


static int luaB_select (lua_State *L) {
  int n = lua_gettop(L);
  if (lua_type(L, 1) == LUA_TSTRING && *lua_tostring(L, 1) == '#') {
    lua_pushinteger(L, n-1);
    return 1;
  }
  else {
    lua_Integer i = luaL_checkinteger(L, 1);
    if (i < 0) i = n + i;
    else if (i > n) i = n;
    luaL_argcheck(L, 1 <= i, 1, "index out of range");
    return n - (int)i;
  }
}


/*
** Continuation function for 'pcall' and 'xpcall'. Both functions
** already pushed a 'true' before doing the call, so in case of success
** 'finishpcall' only has to return everything in the stack minus
** 'extra' values (where 'extra' is exactly the number of items to be
** ignored).
*/
static int finishpcall (lua_State *L, int status, lua_KContext extra) {
  if (l_unlikely(status != LUA_OK && status != LUA_YIELD)) {  /* error? */
    lua_pushboolean(L, 0);  /* first result (false) */
    lua_pushvalue(L, -2);  /* error message */
    return 2;  /* return false, msg */
  }
  else
    return lua_gettop(L) - (int)extra;  /* return all results */
}


static int luaB_pcall (lua_State *L) {
  int status;
  luaL_checkany(L, 1);
  lua_pushboolean(L, 1);  /* first result if no errors */
  lua_insert(L, 1);  /* put it in place */
  status = lua_pcallk(L, lua_gettop(L) - 2, LUA_MULTRET, 0, 0, finishpcall);
  return finishpcall(L, status, 0);
}


/*
** Do a protected call with error handling. After 'lua_rotate', the
** stack will have <f, err, true, f, [args...]>; so, the function passes
** 2 to 'finishpcall' to skip the 2 first values when returning results.
*/
static int luaB_xpcall (lua_State *L) {
  int status;
  int n = lua_gettop(L);
  luaL_checktype(L, 2, LUA_TFUNCTION);  /* check error function */
  lua_pushboolean(L, 1);  /* first result */
  lua_pushvalue(L, 1);  /* function */
  lua_rotate(L, 3, 2);  /* move them below function's arguments */
  status = lua_pcallk(L, n - 2, LUA_MULTRET, 2, 2, finishpcall);
  return finishpcall(L, status, 2);
}


static int luaB_tostring (lua_State *L) {
  luaL_checkany(L, 1);
  luaL_tolstring(L, 1, NULL);
  return 1;
}


static const luaL_Reg base_funcs[] = {
  {"assert", luaB_assert},
  {"collectgarbage", luaB_collectgarbage},
  {"dofile", luaB_dofile},
  {"error", luaB_error},
  {"getmetatable", luaB_getmetatable},
  {"ipairs", luaB_ipairs},
  {"loadfile", luaB_loadfile},
  {"load", luaB_load},
  {"next", luaB_next},
  {"pairs", luaB_pairs},
  {"pcall", luaB_pcall},
  {"print", luaB_print},
  {"println", luaB_println},
  {"warn", luaB_warn},
  {"rawequal", luaB_rawequal},
  {"rawlen", luaB_rawlen},
  {"rawget", luaB_rawget},
  {"rawset", luaB_rawset},
  {"select", luaB_select},
  {"setmetatable", luaB_setmetatable},
  {"__cangjie_setup_class", luaB_setup_class},
  {"__cangjie_extend_type", luaB_extend_type},
  {"__cangjie_copy_to_type", luaB_copy_to_type},
  {"tonumber", luaB_tonumber},
  {"tostring", luaB_tostring},
  {"type", luaB_type},
  {"xpcall", luaB_xpcall},
  /* placeholders */
  {LUA_GNAME, NULL},
  {"_VERSION", NULL},
  {NULL, NULL}
};


LUAMOD_API int luaopen_base (lua_State *L) {
  /* open lib into global table */
  lua_pushglobaltable(L);
  luaL_setfuncs(L, base_funcs, 0);
  /* set global _G */
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, LUA_GNAME);
  /* set global _VERSION */
  lua_pushliteral(L, LUA_VERSION);
  lua_setfield(L, -2, "_VERSION");
  return 1;
}

