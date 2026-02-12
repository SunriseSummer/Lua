# Developer's makefile for building Lua
# see src/include/luaconf.h for further customization

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Source directories
SRCDIR= src
RUNTIME_DIR= $(SRCDIR)/core/runtime
MEMORY_DIR= $(SRCDIR)/core/memory
OBJECT_DIR= $(SRCDIR)/core/object
COMPILER_DIR= $(SRCDIR)/compiler
LIBS_DIR= $(SRCDIR)/libs
APP_DIR= $(SRCDIR)/app
TESTS_DIR= $(SRCDIR)/tests
INCLUDE_DIR= $(SRCDIR)/include

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
MYCFLAGS= $(LOCAL) -std=c99 -DLUA_USE_LINUX -I$(INCLUDE_DIR) -I$(TESTS_DIR)
MYLDFLAGS= -Wl,-E
MYLIBS= -ldl


CC= gcc
CFLAGS= -Wall -O2 $(MYCFLAGS) -fno-stack-protector -fno-common -march=native
AR= ar rc
RANLIB= ranlib
RM= rm -f


# Build output directory
BUILDDIR= build

# == END OF USER SETTINGS. NO NEED TO CHANGE ANYTHING BELOW THIS LINE =========


LIBS = -lm

CORE_T=	$(BUILDDIR)/liblua.a
CORE_O=	$(BUILDDIR)/lapi.o $(BUILDDIR)/lcode.o $(BUILDDIR)/lctype.o \
	$(BUILDDIR)/ldebug.o $(BUILDDIR)/ldo.o $(BUILDDIR)/ldump.o \
	$(BUILDDIR)/lfunc.o $(BUILDDIR)/lgc.o $(BUILDDIR)/llex.o \
	$(BUILDDIR)/lmem.o $(BUILDDIR)/lobject.o $(BUILDDIR)/lopcodes.o \
	$(BUILDDIR)/lparser.o $(BUILDDIR)/lstate.o $(BUILDDIR)/lstring.o \
	$(BUILDDIR)/ltable.o $(BUILDDIR)/ltm.o $(BUILDDIR)/lundump.o \
	$(BUILDDIR)/lvm.o $(BUILDDIR)/lzio.o $(BUILDDIR)/ltests.o
AUX_O=	$(BUILDDIR)/lauxlib.o
LIB_O=	$(BUILDDIR)/lbaselib.o $(BUILDDIR)/lbaselib_cj.o $(BUILDDIR)/lbaselib_cj_string.o \
	$(BUILDDIR)/lbaselib_cj_option.o $(BUILDDIR)/lbaselib_cj_range.o \
	$(BUILDDIR)/lcollection_arraylist.o \
	$(BUILDDIR)/lcollection_hashmap.o $(BUILDDIR)/lcollection_hashset.o \
	$(BUILDDIR)/lcollection_arraystack.o $(BUILDDIR)/lcjutf8.o \
	$(BUILDDIR)/ldblib.o \
	$(BUILDDIR)/liolib.o $(BUILDDIR)/lmathlib.o $(BUILDDIR)/loslib.o \
	$(BUILDDIR)/ltablib.o $(BUILDDIR)/lstrlib.o $(BUILDDIR)/lutf8lib.o \
	$(BUILDDIR)/loadlib.o $(BUILDDIR)/lcorolib.o $(BUILDDIR)/linit.o

LUA_T=	lua
LUA_O=	$(BUILDDIR)/lua.o


ALL_T= $(CORE_T) $(LUA_T)
ALL_O= $(CORE_O) $(LUA_O) $(AUX_O) $(LIB_O)
ALL_A= $(CORE_T)

all:	$(BUILDDIR) $(ALL_T)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

o:	$(ALL_O)

a:	$(ALL_A)

$(CORE_T): $(CORE_O) $(AUX_O) $(LIB_O)
	$(AR) $@ $?
	$(RANLIB) $@

$(LUA_T): $(LUA_O) $(CORE_T)
	$(CC) -o $@ $(MYLDFLAGS) $(LUA_O) $(CORE_T) $(LIBS) $(MYLIBS) $(DL)


clean:
	$(RM) -r $(BUILDDIR) $(LUA_T)

depend:
	@$(CC) $(CFLAGS) -MM $(RUNTIME_DIR)/*.c $(MEMORY_DIR)/*.c $(OBJECT_DIR)/*.c $(COMPILER_DIR)/*.c $(LIBS_DIR)/*.c $(APP_DIR)/*.c $(TESTS_DIR)/*.c

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

$(ALL_O): makefile $(TESTS_DIR)/ltests.h

# Compile rules for each source directory
$(BUILDDIR)/%.o: $(RUNTIME_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(MEMORY_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(OBJECT_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(COMPILER_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(LIBS_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(APP_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(TESTS_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

# (end of Makefile)
