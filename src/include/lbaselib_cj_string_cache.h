/*
** UTF-8 cache helpers for Cangjie string operations.
** Extracted from lbaselib_cj_string.c for reuse and clarity.
** See Copyright Notice in lua.h
*/

#ifndef lbaselib_cj_string_cache_h
#define lbaselib_cj_string_cache_h

#include <stddef.h>

#include "lua.h"
#include "llimits.h"

LUAI_FUNC void utf8_cache_init (lua_State *L);
LUAI_FUNC lua_Integer utf8_cached_charcount (lua_State *L, int idx);
LUAI_FUNC const lua_Integer *utf8_get_cached_offsets (lua_State *L, int idx,
                                                      lua_Integer *charCount);
LUAI_FUNC const lua_Integer *utf8_build_index_cache (lua_State *L, int idx);
LUAI_FUNC int utf8_single_pass_index (const char *s, size_t len,
                                      lua_Integer charIdx,
                                      lua_Integer *byteOff, size_t *charLen,
                                      lua_Integer *totalChars);

#endif
