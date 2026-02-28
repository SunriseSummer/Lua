# Developer's makefile for building Lua
# see luaconf.h for further customization

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Warnings valid for both C and C++
CWARNSCPP= \
	-Wfatal-errors \
	-Wextra \
	-Wshadow \
	-Wundef \
	-Wwrite-strings \
	-Wredundant-decls \
	-Wdisabled-optimization \
	-Wdouble-promotion \
	-Wmissing-declarations \
	-Wconversion \
        # the next warnings might be useful sometimes,
	# but usually they generate too much noise
	# -Wstrict-overflow=2 \
	# -Werror \
	# -pedantic   # warns if we use jump tables \
	# -Wformat=2 \
	# -Wcast-qual \


# Warnings for gcc, not valid for clang
CWARNGCC= \
	-Wlogical-op \
	-Wno-aggressive-loop-optimizations \


# The next warnings are neither valid nor needed for C++
CWARNSC= -Wdeclaration-after-statement \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wstrict-prototypes \
	-Wc++-compat \
	-Wold-style-definition \


CWARNS= $(CWARNSCPP) $(CWARNSC) $(CWARNGCC)

# Some useful compiler options for internal tests:
# -DLUAI_ASSERT turns on all assertions inside Lua.
# -DHARDSTACKTESTS forces a reallocation of the stack at every point where
# the stack can be reallocated.
# -DHARDMEMTESTS forces a full collection at all points where the collector
# can run.
# -DEMERGENCYGCTESTS forces an emergency collection at every single allocation.
# -DEXTERNMEMCHECK removes internal consistency checking of blocks being
# deallocated (useful when an external tool like valgrind does the check).
# -DMAXINDEXRK=k limits range of constants in RK instruction operands.
# -DLUA_COMPAT_5_3

# -pg -malign-double
# -DLUA_USE_CTYPE -DLUA_USE_APICHECK

# The following options help detect "undefined behavior"s that seldom
# create problems; some are only available in newer gcc versions. To
# use some of them, we also have to define an environment variable
# ASAN_OPTIONS="detect_invalid_pointer_pairs=2".
# -fsanitize=undefined
# -fsanitize=pointer-subtract -fsanitize=address -fsanitize=pointer-compare
# TESTS= -DLUA_USER_H='"ltests.h"' -Og -g


LOCAL = $(TESTS) $(CWARNS)


# To enable Linux goodies, -DLUA_USE_LINUX
# For C89, "-std=c89 -DLUA_USE_C89"
# Note that Linux/Posix options are not compatible with C89
MYCFLAGS= $(LOCAL) -std=c99 -DLUA_USE_LINUX -Isrc
MYLDFLAGS= -Wl,-E
MYLIBS= -ldl


CC= gcc
CFLAGS= -Wall -O2 $(MYCFLAGS) -fno-stack-protector -fno-common -march=native
AR= ar rc
RANLIB= ranlib
RM= rm -f



# == END OF USER SETTINGS. NO NEED TO CHANGE ANYTHING BELOW THIS LINE =========


LIBS = -lm

SRCDIR= src

CORE_T=	liblua.a
CORE_O=	$(SRCDIR)/lapi.o $(SRCDIR)/lcode.o $(SRCDIR)/lctype.o $(SRCDIR)/ldebug.o \
	$(SRCDIR)/ldo.o $(SRCDIR)/ldump.o $(SRCDIR)/lfunc.o $(SRCDIR)/lgc.o \
	$(SRCDIR)/llex.o $(SRCDIR)/lmem.o $(SRCDIR)/lobject.o $(SRCDIR)/lopcodes.o \
	$(SRCDIR)/lparser.o $(SRCDIR)/lstate.o $(SRCDIR)/lstring.o $(SRCDIR)/ltable.o \
	$(SRCDIR)/ltm.o $(SRCDIR)/lundump.o $(SRCDIR)/lvm.o $(SRCDIR)/lzio.o \
	$(SRCDIR)/ltests.o
AUX_O=	$(SRCDIR)/lauxlib.o
LIB_O=	$(SRCDIR)/lbaselib.o $(SRCDIR)/ldblib.o $(SRCDIR)/liolib.o \
	$(SRCDIR)/lmathlib.o $(SRCDIR)/loslib.o $(SRCDIR)/ltablib.o \
	$(SRCDIR)/lstrlib.o $(SRCDIR)/lutf8lib.o $(SRCDIR)/loadlib.o \
	$(SRCDIR)/lcorolib.o $(SRCDIR)/linit.o

LUA_T=	lua
LUA_O=	$(SRCDIR)/lua.o


ALL_T= $(CORE_T) $(LUA_T)
ALL_O= $(CORE_O) $(LUA_O) $(AUX_O) $(LIB_O)
ALL_A= $(CORE_T)

all:	$(ALL_T)
	touch all

o:	$(ALL_O)

a:	$(ALL_A)

$(CORE_T): $(CORE_O) $(AUX_O) $(LIB_O)
	$(AR) $@ $?
	$(RANLIB) $@

$(LUA_T): $(LUA_O) $(CORE_T)
	$(CC) -o $@ $(MYLDFLAGS) $(LUA_O) $(CORE_T) $(LIBS) $(MYLIBS) $(DL)

$(SRCDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -I$(SRCDIR) -c -o $@ $<


clean:
	$(RM) $(ALL_T) $(ALL_O)

depend:
	@$(CC) $(CFLAGS) -I$(SRCDIR) -MM $(SRCDIR)/l*.c

echo:
	@echo "CC = $(CC)"
	@echo "CFLAGS = $(CFLAGS)"
	@echo "AR = $(AR)"
	@echo "RANLIB = $(RANLIB)"
	@echo "RM = $(RM)"
	@echo "MYCFLAGS = $(MYCFLAGS)"
	@echo "MYLDFLAGS = $(MYLDFLAGS)"
	@echo "MYLIBS = $(MYLIBS)"
	@echo "DL = $(DL)"

$(ALL_O): makefile $(SRCDIR)/ltests.h

# DO NOT EDIT
# automatically made with 'gcc -MM l*.c'

$(SRCDIR)/lapi.o: $(SRCDIR)/lapi.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h $(SRCDIR)/lstring.h \
 $(SRCDIR)/ltable.h $(SRCDIR)/lundump.h $(SRCDIR)/lvm.h
$(SRCDIR)/lauxlib.o: $(SRCDIR)/lauxlib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/llimits.h
$(SRCDIR)/lbaselib.o: $(SRCDIR)/lbaselib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/lcode.o: $(SRCDIR)/lcode.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lcode.h $(SRCDIR)/llex.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/lopcodes.h $(SRCDIR)/lparser.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/ltm.h \
 $(SRCDIR)/ldo.h $(SRCDIR)/lgc.h $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h $(SRCDIR)/lvm.h $(SRCDIR)/lopnames.h
$(SRCDIR)/lcorolib.o: $(SRCDIR)/lcorolib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/lctype.o: $(SRCDIR)/lctype.c $(SRCDIR)/lprefix.h $(SRCDIR)/lctype.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/llimits.h
$(SRCDIR)/ldblib.o: $(SRCDIR)/ldblib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h $(SRCDIR)/llimits.h
$(SRCDIR)/ldebug.o: $(SRCDIR)/ldebug.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/lcode.h $(SRCDIR)/llex.h $(SRCDIR)/lopcodes.h $(SRCDIR)/lparser.h \
 $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h $(SRCDIR)/ltable.h $(SRCDIR)/lvm.h
$(SRCDIR)/ldo.o: $(SRCDIR)/ldo.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h $(SRCDIR)/lopcodes.h \
 $(SRCDIR)/lparser.h $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h $(SRCDIR)/lundump.h $(SRCDIR)/lvm.h
$(SRCDIR)/ldump.o: $(SRCDIR)/ldump.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/lgc.h $(SRCDIR)/ltable.h $(SRCDIR)/lundump.h
$(SRCDIR)/lfunc.o: $(SRCDIR)/lfunc.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h
$(SRCDIR)/lgc.o: $(SRCDIR)/lgc.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h
$(SRCDIR)/linit.o: $(SRCDIR)/linit.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lualib.h $(SRCDIR)/lauxlib.h $(SRCDIR)/llimits.h
$(SRCDIR)/liolib.o: $(SRCDIR)/liolib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h $(SRCDIR)/llimits.h
$(SRCDIR)/llex.o: $(SRCDIR)/llex.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lctype.h $(SRCDIR)/llimits.h $(SRCDIR)/ldebug.h \
 $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lgc.h $(SRCDIR)/llex.h $(SRCDIR)/lparser.h \
 $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h
$(SRCDIR)/lmathlib.o: $(SRCDIR)/lmathlib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/lmem.o: $(SRCDIR)/lmem.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lgc.h
$(SRCDIR)/loadlib.o: $(SRCDIR)/loadlib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/lobject.o: $(SRCDIR)/lobject.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lctype.h $(SRCDIR)/llimits.h \
 $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h \
 $(SRCDIR)/lvm.h
$(SRCDIR)/lopcodes.o: $(SRCDIR)/lopcodes.c $(SRCDIR)/lprefix.h $(SRCDIR)/lopcodes.h $(SRCDIR)/llimits.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h \
 $(SRCDIR)/lobject.h
$(SRCDIR)/loslib.o: $(SRCDIR)/loslib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h $(SRCDIR)/llimits.h
$(SRCDIR)/lparser.o: $(SRCDIR)/lparser.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lcode.h $(SRCDIR)/llex.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/lopcodes.h $(SRCDIR)/lparser.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/ltm.h \
 $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h $(SRCDIR)/ltable.h
$(SRCDIR)/lstate.o: $(SRCDIR)/lstate.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h $(SRCDIR)/llex.h \
 $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h
$(SRCDIR)/lstring.o: $(SRCDIR)/lstring.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h
$(SRCDIR)/lstrlib.o: $(SRCDIR)/lstrlib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/ltable.o: $(SRCDIR)/ltable.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lgc.h $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h $(SRCDIR)/lvm.h
$(SRCDIR)/ltablib.o: $(SRCDIR)/ltablib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/ltests.o: $(SRCDIR)/ltests.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lcode.h $(SRCDIR)/llex.h $(SRCDIR)/lopcodes.h \
 $(SRCDIR)/lparser.h $(SRCDIR)/lctype.h $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lopnames.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h \
 $(SRCDIR)/ltable.h $(SRCDIR)/lualib.h
$(SRCDIR)/ltm.o: $(SRCDIR)/ltm.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h $(SRCDIR)/lobject.h \
 $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lgc.h $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h $(SRCDIR)/lvm.h
$(SRCDIR)/lua.o: $(SRCDIR)/lua.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h $(SRCDIR)/llimits.h
$(SRCDIR)/lundump.o: $(SRCDIR)/lundump.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/ldebug.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/llimits.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lstring.h $(SRCDIR)/lgc.h \
 $(SRCDIR)/ltable.h $(SRCDIR)/lundump.h
$(SRCDIR)/lutf8lib.o: $(SRCDIR)/lutf8lib.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lauxlib.h $(SRCDIR)/lualib.h \
 $(SRCDIR)/llimits.h
$(SRCDIR)/lvm.o: $(SRCDIR)/lvm.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h $(SRCDIR)/ldebug.h $(SRCDIR)/ldo.h $(SRCDIR)/lfunc.h $(SRCDIR)/lgc.h $(SRCDIR)/lopcodes.h \
 $(SRCDIR)/lstring.h $(SRCDIR)/ltable.h $(SRCDIR)/lvm.h $(SRCDIR)/ljumptab.h
$(SRCDIR)/lzio.o: $(SRCDIR)/lzio.c $(SRCDIR)/lprefix.h $(SRCDIR)/lua.h $(SRCDIR)/luaconf.h $(SRCDIR)/lapi.h $(SRCDIR)/llimits.h $(SRCDIR)/lstate.h \
 $(SRCDIR)/lobject.h $(SRCDIR)/ltm.h $(SRCDIR)/lzio.h $(SRCDIR)/lmem.h

# (end of Makefile)
