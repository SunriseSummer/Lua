/*
** Cangjie string UTF-8 cache support.
** Provides shared cache helpers for character counts and index offsets.
** See Copyright Notice in lua.h
*/

#define lbaselib_cj_string_cache_c
#define LUA_LIB

#include "lprefix.h"

#include "lua.h"

#include "lbaselib_cj_string_cache.h"
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
void utf8_cache_init (lua_State *L) {
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
** Retrieve the cached index offset table for a string at stack index 'idx'.
** Returns a pointer to the lua_Integer array (byte offsets for each char),
** or NULL if not cached. Sets *charCount to the number of characters.
** The array has charCount+1 entries: offsets[i] = byte offset of char i,
** offsets[charCount] = total byte length.
*/
const lua_Integer *utf8_get_cached_offsets (lua_State *L, int idx,
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
** Get cached UTF-8 character count for a string at stack index 'idx'.
** If not cached, computes it, caches it, and returns the count.
** Returns the character count (or byte length as fallback for invalid UTF-8).
*/
lua_Integer utf8_cached_charcount (lua_State *L, int idx) {
  lua_Integer cc;
  size_t len;
  const char *s = lua_tolstring(L, idx, &len);
  if (s == NULL) return 0;

  /* Index cache implies a known character count */
  {
    lua_Integer cachedCC;
    if (utf8_get_cached_offsets(L, idx, &cachedCC) != NULL && cachedCC >= 0)
      return cachedCC;
  }

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
** Build and cache the index offset table for a string at stack index 'idx'.
** Returns a pointer to the cached lua_Integer array.
** The array has charCount+1 entries.
*/
const lua_Integer *utf8_build_index_cache (lua_State *L, int idx) {
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
int utf8_single_pass_index (const char *s, size_t len,
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
