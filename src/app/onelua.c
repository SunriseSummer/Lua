/*
** Lua core, libraries, and interpreter in a single file.
** Compiling just this file generates a complete Lua stand-alone
** program:
**
** $ gcc -O2 -std=c99 -o lua onelua.c -lm
**
** or (for C89)
**
** $ gcc -O2 -std=c89 -DLUA_USE_C89 -o lua onelua.c -lm
**
** or (for Linux)
**
** gcc -O2 -o lua -DLUA_USE_LINUX -Wl,-E onelua.c -lm -ldl
**
*/

/* default is to build the full interpreter */
#ifndef MAKE_LIB
#ifndef MAKE_LUAC
#ifndef MAKE_LUA
#define MAKE_LUA
#endif
#endif
#endif


/*
** Choose suitable platform-specific features. Default is no
** platform-specific features. Some of these options may need extra
** libraries such as -ldl -lreadline -lncurses
*/
#if 0
#define LUA_USE_LINUX
#define LUA_USE_MACOSX
#define LUA_USE_POSIX
#endif


/*
** Other specific features
*/
#if 0
#define LUA_32BITS
#define LUA_USE_C89
#endif


/* no need to change anything below this line ----------------------------- */

#include "lprefix.h"

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* setup for luaconf.h */
#define LUA_CORE
#define LUA_LIB

#include "luaconf.h"

/* do not export internal symbols */
#undef LUAI_FUNC
#undef LUAI_DDEC
#undef LUAI_DDEF
#define LUAI_FUNC	static
#define LUAI_DDEC(def)	/* empty */
#define LUAI_DDEF	static

/* core -- used by all */
#include "../core/runtime/lzio.c"
#include "../core/object/lctype.c"
#include "../core/runtime/lopcodes.c"
#include "../core/memory/lmem.c"
#include "../compiler/lundump.c"
#include "../compiler/ldump.c"
#include "../core/runtime/lstate.c"
#include "../core/memory/lgc.c"
#include "../compiler/llex.c"
#include "../compiler/lcode.c"
#include "../compiler/lparser.c"
#include "../core/runtime/ldebug.c"
#include "../core/runtime/lfunc.c"
#include "../core/object/lobject.c"
#include "../core/object/ltm.c"
#include "../core/object/lstring.c"
#include "../core/object/ltable.c"
#include "../core/runtime/ldo.c"
#include "../core/runtime/lvm.c"
#include "../core/runtime/lapi.c"

/* auxiliary library -- used by all */
#include "../libs/lauxlib.c"

/* standard library  -- not used by luac */
#ifndef MAKE_LUAC
#include "../libs/lbaselib.c"
#include "../libs/lbaselib_cj.c"
#include "../libs/lcorolib.c"
#include "../libs/ldblib.c"
#include "../libs/liolib.c"
#include "../libs/lmathlib.c"
#include "../libs/loadlib.c"
#include "../libs/loslib.c"
#include "../libs/lstrlib.c"
#include "../libs/ltablib.c"
#include "../libs/lutf8lib.c"
#include "../libs/linit.c"
#endif

/* test library -- used only for internal development */
#if defined(LUA_DEBUG)
#include "../tests/ltests.c"
#endif

/* lua */
#ifdef MAKE_LUA
#include "lua.c"
#endif

/* luac */
#ifdef MAKE_LUAC
#include "luac.c"
#endif
