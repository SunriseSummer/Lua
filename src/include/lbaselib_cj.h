/*
** Cangjie OOP runtime support - extracted from lbaselib.c
** Functions for class/struct instantiation, method binding,
** inheritance chain walking, enum support, and type checking.
** See Copyright Notice in lua.h
*/

#ifndef lbaselib_cj_h
#define lbaselib_cj_h

#include "lua.h"
#include "llimits.h"

/* Cangjie OOP runtime */
LUAI_FUNC int luaB_setup_class (lua_State *L);
LUAI_FUNC int luaB_extend_type (lua_State *L);
LUAI_FUNC int luaB_copy_to_type (lua_State *L);
LUAI_FUNC int luaB_set_parent (lua_State *L);
LUAI_FUNC int luaB_super_init (lua_State *L);
LUAI_FUNC int luaB_is_instance (lua_State *L);
LUAI_FUNC int luaB_match_tag (lua_State *L);
LUAI_FUNC int luaB_match_tuple (lua_State *L);
LUAI_FUNC int luaB_setup_enum (lua_State *L);
LUAI_FUNC int luaB_tuple (lua_State *L);
LUAI_FUNC int luaB_named_call (lua_State *L);
LUAI_FUNC int luaB_overload (lua_State *L);
LUAI_FUNC int luaB_array_init (lua_State *L);
LUAI_FUNC int luaB_option_init (lua_State *L);
LUAI_FUNC int luaB_coalesce (lua_State *L);
LUAI_FUNC int luaB_array_slice (lua_State *L);
LUAI_FUNC int luaB_array_slice_set (lua_State *L);
LUAI_FUNC int luaB_iter (lua_State *L);
LUAI_FUNC int luaB_apply_interface (lua_State *L);

/* Cangjie string support */
LUAI_FUNC int luaB_str_index (lua_State *L);
LUAI_FUNC int luaB_str_newindex (lua_State *L);
LUAI_FUNC int luaB_str_slice (lua_State *L);
LUAI_FUNC int luaB_setup_string_meta (lua_State *L);

/* Cangjie type conversion functions */
LUAI_FUNC int luaB_cangjie_int64 (lua_State *L);
LUAI_FUNC int luaB_cangjie_float64 (lua_State *L);
LUAI_FUNC int luaB_cangjie_string (lua_State *L);
LUAI_FUNC int luaB_cangjie_bool (lua_State *L);
LUAI_FUNC int luaB_cangjie_rune (lua_State *L);

#endif
