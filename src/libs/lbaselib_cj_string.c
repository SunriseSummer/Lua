/*
** $Id: lbaselib_cj_string.c $
** Cangjie string support - UTF-8 caching, string member methods,
** string indexing/slicing, byte array conversion, and string metatable.
** Split from lbaselib_cj.c
**
** Contents:
**   utf8_cache_init              — Initialize UTF-8 cache tables
**   utf8_cached_charcount        — Get/cache UTF-8 character count
**   utf8_get_cached_offsets      — Retrieve cached char-to-byte offset table
**   utf8_build_index_cache       — Build and cache offset table for O(1) indexing
**   utf8_single_pass_index       — Find char at index in one scan (no cache)
**   str_isEmpty .. str_count_cj  — Built-in string methods
**   str_fromUtf8                 — Construct string from byte array
**   str_cacheIndex               — Pre-build index cache for a string
**   luaB_str_index               — String __index metamethod
**   luaB_str_newindex            — String __newindex (immutability guard)
**   luaB_str_slice               — UTF-8-aware substring extraction
**   luaB_setup_string_meta       — Install string metatable at init time
**
** See Copyright Notice in lua.h
*/

#define lbaselib_cj_string_c
#define LUA_LIB

#include "lprefix.h"

#include <string.h>
#include <stdio.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "lbaselib_cj.h"
#include "lbaselib_cj_helpers.h"
#include "lcjutf8.h"


/*
** ============================================================
** UTF-8 caching infrastructure
** ============================================================
*/

/* Registry keys for cache tables */
static const char CJ_UTF8_CHARCOUNT_KEY[] = "__cj_utf8_cc";
static const char CJ_UTF8_INDEX_KEY[] = "__cj_utf8_idx";

/*
** Initialize the UTF-8 cache tables in the registry.
** Called once during luaB_setup_string_meta.
*/
static void utf8_cache_init (lua_State *L) {
  /* Create char-count cache: weak-keyed table */
  lua_newtable(L);                        /* cache table */
  lua_newtable(L);                        /* metatable */
  lua_pushliteral(L, "k");
  lua_setfield(L, -2, "__mode");          /* weak keys */
  lua_setmetatable(L, -2);
  lua_setfield(L, LUA_REGISTRYINDEX, CJ_UTF8_CHARCOUNT_KEY);

  /* Create index-offset cache: weak-keyed table */
  lua_newtable(L);
  lua_newtable(L);
  lua_pushliteral(L, "k");
  lua_setfield(L, -2, "__mode");
  lua_setmetatable(L, -2);
  lua_setfield(L, LUA_REGISTRYINDEX, CJ_UTF8_INDEX_KEY);
}

/*
** Get cached UTF-8 character count for a string at stack index 'idx'.
** If not cached, computes it, caches it, and returns the count.
** Returns the character count (or byte length as fallback for invalid UTF-8).
*/
static lua_Integer utf8_cached_charcount (lua_State *L, int idx) {
  lua_Integer cc;
  size_t len;
  const char *s = lua_tolstring(L, idx, &len);
  if (s == NULL) return 0;

  /* Look up in cache */
  lua_getfield(L, LUA_REGISTRYINDEX, CJ_UTF8_CHARCOUNT_KEY);
  lua_pushvalue(L, idx);      /* push the string as key */
  lua_rawget(L, -2);          /* cache[string] */
  if (!lua_isnil(L, -1)) {
    cc = lua_tointeger(L, -1);
    lua_pop(L, 2);  /* pop value and cache table */
    return cc;
  }
  lua_pop(L, 1);  /* pop nil */

  /* Compute and cache */
  cc = cjU_charcount(s, len);
  if (cc < 0) cc = (lua_Integer)len;  /* invalid UTF-8: fall back to byte length */
  lua_pushvalue(L, idx);      /* key: the string */
  lua_pushinteger(L, cc);     /* value: char count */
  lua_rawset(L, -3);          /* cache[string] = cc */
  lua_pop(L, 1);              /* pop cache table */
  return cc;
}

/*
** Retrieve the cached index offset table for a string at stack index 'idx'.
** Returns a pointer to the lua_Integer array (byte offsets for each char),
** or NULL if not cached. Sets *charCount to the number of characters.
** The array has charCount+1 entries: offsets[i] = byte offset of char i,
** offsets[charCount] = total byte length.
*/
static const lua_Integer *utf8_get_cached_offsets (lua_State *L, int idx,
                                                   lua_Integer *charCount) {
  const lua_Integer *offsets;
  lua_getfield(L, LUA_REGISTRYINDEX, CJ_UTF8_INDEX_KEY);
  lua_pushvalue(L, idx);
  lua_rawget(L, -2);
  if (lua_isuserdata(L, -1)) {
    size_t udSize = lua_rawlen(L, -1);
    /* userdata has cc+1 entries (offsets[0..cc-1] + sentinel), so cc = entries - 1 */
    lua_Integer nChars = (lua_Integer)(udSize / sizeof(lua_Integer)) - 1;
    offsets = (const lua_Integer *)lua_touserdata(L, -1);
    if (charCount) *charCount = nChars;
    lua_pop(L, 2);  /* pop userdata and cache table */
    return offsets;
  }
  lua_pop(L, 2);  /* pop nil and cache table */
  if (charCount) *charCount = -1;
  return NULL;
}

/*
** Build and cache the index offset table for a string at stack index 'idx'.
** Returns a pointer to the cached lua_Integer array.
** The array has charCount+1 entries.
*/
static const lua_Integer *utf8_build_index_cache (lua_State *L, int idx) {
  size_t len;
  const char *s = lua_tolstring(L, idx, &len);
  lua_Integer cc, i;
  lua_Integer *offsets;
  size_t pos;
  if (s == NULL) return NULL;

  /* First compute char count (invalid UTF-8: fall back to byte length) */
  cc = cjU_charcount(s, len);
  if (cc < 0) cc = (lua_Integer)len;

  /* Also cache the char count */
  lua_getfield(L, LUA_REGISTRYINDEX, CJ_UTF8_CHARCOUNT_KEY);
  lua_pushvalue(L, idx);
  lua_pushinteger(L, cc);
  lua_rawset(L, -3);
  lua_pop(L, 1);

  /* Allocate userdata for offsets: cc+1 entries */
  offsets = (lua_Integer *)lua_newuserdatauv(L, (size_t)(cc + 1) * sizeof(lua_Integer), 0);

  /* Fill the offset table */
  pos = 0;
  i = 0;
  while (pos < len && i < cc) {
    const char *next;
    offsets[i] = (lua_Integer)pos;
    next = cjU_decode(s + pos, NULL);
    if (next == NULL) { pos++; }  /* invalid sequence: skip one byte */
    else { pos = (size_t)(next - s); }
    i++;
  }
  offsets[cc] = (lua_Integer)len;  /* sentinel: one past end */

  /* Store in cache: idx_cache[string] = userdata */
  lua_getfield(L, LUA_REGISTRYINDEX, CJ_UTF8_INDEX_KEY);
  lua_pushvalue(L, idx);      /* key: the string */
  lua_pushvalue(L, -3);       /* value: the userdata */
  lua_rawset(L, -3);
  lua_pop(L, 2);  /* pop cache table and userdata */

  return offsets;
}

/*
** Single-pass UTF-8 index: find the byte offset and length of the
** charIdx-th (0-based) character.  Returns 1 on success, 0 on out-of-range.
** On success, sets *byteOff and *charLen.
** On failure, sets *totalChars to the total character count.
*/
static int utf8_single_pass_index (const char *s, size_t len,
                                   lua_Integer charIdx,
                                   lua_Integer *byteOff, size_t *charLen,
                                   lua_Integer *totalChars) {
  lua_Integer n = 0;
  size_t pos = 0;
  if (charIdx < 0) {
    /* Still need total count for error message */
    *totalChars = cjU_charcount(s, len);
    if (*totalChars < 0) *totalChars = (lua_Integer)len;
    return 0;
  }
  while (pos < len) {
    const char *next = cjU_decode(s + pos, NULL);
    size_t clen;
    if (next == NULL) { next = s + pos + 1; }
    clen = (size_t)(next - (s + pos));
    if (n == charIdx) {
      *byteOff = (lua_Integer)pos;
      *charLen = clen;
      return 1;  /* found */
    }
    pos = (size_t)(next - s);
    n++;
  }
  /* Out of range: n is the total char count */
  *totalChars = n;
  return 0;
}


/*
** ============================================================
** Cangjie string member methods (built-in)
** ============================================================
*/

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
      const char *next = cjU_decode(s + pos, NULL);
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
    const char *next = cjU_decode(s + pos, NULL);
    size_t clen;
    long cp;
    if (next == NULL) {
      next = s + pos + 1;
    }
    clen = (size_t)(next - (s + pos));
    cp = cjU_decodesingle(s + pos, clen);
    if (cp >= 0)
      lua_pushrune(L, (lua_Integer)cp);
    else
      lua_pushrune(L, 0xFFFD);  /* replacement character for invalid decode */
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
  byteOff = cjU_byteoffset(s, slen, fromCharIdx);
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
    const char *next = cjU_decode(s + pos, NULL);
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
  lua_Integer charCount = utf8_cached_charcount(L, 1);
  lua_Integer fromCharIdx = luaL_optinteger(L, 3, charCount);
  lua_Integer byteOff, lastBytePos, charIdx;
  size_t pos;
  const char *search_end;
  if (charCount < 0) charCount = 0;
  if (fromCharIdx > charCount) fromCharIdx = charCount;
  if (fromCharIdx < 0) fromCharIdx = 0;
  byteOff = cjU_byteoffset(s, slen, fromCharIdx);
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
    const char *next = cjU_decode(s + pos, NULL);
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
    lua_Integer cc = utf8_cached_charcount(L, 1);
    lua_pushinteger(L, cc + 1);
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

/* String.fromUtf8(byteArray) -> String
** Reconstruct a string from a 0-based byte array table. */
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


/*
** s:cacheIndex() -> self
** Build an index offset table so that subsequent indexing is O(1).
** Returns the string itself for chaining.
*/
static int str_cacheIndex (lua_State *L) {
  luaL_checkstring(L, 1);
  utf8_build_index_cache(L, 1);
  lua_pushvalue(L, 1);  /* return self */
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
  {"cacheIndex", str_cacheIndex},
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
  if (lua_type(L, 2) == LUA_TINT64) {
    lua_Integer idx = lua_tointeger(L, 2);
    lua_Integer cachedCC;
    const lua_Integer *offsets;

    /* Try index cache first (O(1) if available) */
    offsets = utf8_get_cached_offsets(L, 1, &cachedCC);
    if (offsets != NULL) {
      if (idx < 0 || idx >= cachedCC) {
        return luaL_error(L, "string index %I out of range (size %I)",
                          (long long)idx, (long long)cachedCC);
      }
      {
        size_t clen = (size_t)(offsets[idx + 1] - offsets[idx]);
        long cp = cjU_decodesingle(s + offsets[idx], clen);
        if (cp >= 0)
          lua_pushrune(L, (lua_Integer)cp);
        else
          lua_pushrune(L, 0xFFFD);  /* replacement character */
        return 1;
      }
    }

    /* Single-pass scan: find char at idx without separate charcount call */
    {
      lua_Integer byteOff;
      size_t clen;
      lua_Integer totalChars;
      if (utf8_single_pass_index(s, len, idx, &byteOff, &clen, &totalChars)) {
        long cp = cjU_decodesingle(s + byteOff, clen);
        if (cp >= 0)
          lua_pushrune(L, (lua_Integer)cp);
        else
          lua_pushrune(L, 0xFFFD);  /* replacement character */
        return 1;
      }
      /* Out of range */
      return luaL_error(L, "string index %I out of range (size %I)",
                        (long long)idx, (long long)totalChars);
    }
  }
  if (lua_type(L, 2) == LUA_TSTRING) {
    const char *key = lua_tostring(L, 2);
    if (strcmp(key, "size") == 0) {
      lua_pushinteger(L, utf8_cached_charcount(L, 1));
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
          lua_pushcclosure(L, cangjie_bound_method, 2);
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
** __add metamethod for strings.
** Handles: string + string, string + Rune, Rune + string
** by converting operands to strings and concatenating.
*/
static int luaB_str_add (lua_State *L) {
  luaL_Buffer b;
  size_t l;
  const char *s;
  luaL_buffinit(L, &b);
  /* Process first operand */
  if (lua_isrune(L, 1)) {
    char buf[8];
    int nbytes = cjU_utf8encode(buf, lua_torune(L, 1));
    luaL_addlstring(&b, buf, (size_t)nbytes);
  } else {
    s = luaL_checklstring(L, 1, &l);
    luaL_addlstring(&b, s, l);
  }
  /* Process second operand */
  if (lua_isrune(L, 2)) {
    char buf[8];
    int nbytes = cjU_utf8encode(buf, lua_torune(L, 2));
    luaL_addlstring(&b, buf, (size_t)nbytes);
  } else {
    s = luaL_checklstring(L, 2, &l);
    luaL_addlstring(&b, s, l);
  }
  luaL_pushresult(&b);
  return 1;
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
  lua_Integer charCount;
  lua_Integer startByte, endByte;
  const lua_Integer *offsets;

  if (!inclusive) end--;
  if (start < 0) start = 0;

  /* Try index cache first */
  offsets = utf8_get_cached_offsets(L, 1, &charCount);
  if (offsets != NULL) {
    if (end >= charCount) end = charCount - 1;
    if (end < start) {
      lua_pushliteral(L, "");
      return 1;
    }
    startByte = offsets[start];
    endByte = offsets[end + 1];
    lua_pushlstring(L, s + startByte, (size_t)(endByte - startByte));
    return 1;
  }

  /* Use cached char count for boundary clamping */
  charCount = utf8_cached_charcount(L, 1);
  if (end >= charCount) end = charCount - 1;
  if (end < start) {
    lua_pushliteral(L, "");
    return 1;
  }
  startByte = cjU_byteoffset(s, len, start);
  endByte = cjU_byteoffset(s, len, end + 1);
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
** ============================================================
** Byte array / string conversion helpers
** Used by Array<Byte> <-> String interop.
** ============================================================
*/

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
  luaL_checkstring(L, 1);
  lua_pushinteger(L, utf8_cached_charcount(L, 1));
  return 1;
}


/*
** ============================================================
** String metatable setup
** Installs __index, __newindex, __len, and __add metamethods
** on the shared string metatable so all strings get Cangjie
** semantics (UTF-8 indexing, method calls, immutability).
** ============================================================
*/

/*
** Set up string metatable for Cangjie-style indexing.
** Called during interpreter initialization.
*/
int luaB_setup_string_meta (lua_State *L) {
  /* Initialize UTF-8 cache tables */
  utf8_cache_init(L);

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
  /* Set __add to handle string+Rune, Rune+string concatenation */
  lua_pushcfunction(L, luaB_str_add);
  lua_setfield(L, -2, "__add");

  /* Register String.fromUtf8 as a global helper */
  lua_pushcfunction(L, str_fromUtf8);
  lua_setglobal(L, "__cangjie_string_from_byte_array");

  lua_pop(L, 2);  /* pop metatable and "" */
  return 0;
}
