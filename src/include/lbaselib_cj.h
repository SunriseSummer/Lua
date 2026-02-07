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
LUAI_FUNC int luaB_is_instance (lua_State *L);
LUAI_FUNC int luaB_match_tag (lua_State *L);
LUAI_FUNC int luaB_match_tuple (lua_State *L);
LUAI_FUNC int luaB_setup_enum (lua_State *L);
LUAI_FUNC int luaB_tuple (lua_State *L);
LUAI_FUNC int luaB_named_call (lua_State *L);
LUAI_FUNC int luaB_overload (lua_State *L);

#endif
