cmake_minimum_required(VERSION 3.10)
project(Lua VERSION 5.5 LANGUAGES C)

set(CMAKE_C_STANDARD 99)

# Platform detection
if(UNIX AND NOT APPLE)
  add_definitions(-DLUA_USE_LINUX)
  set(PLATFORM_LIBS m dl)
elseif(APPLE)
  add_definitions(-DLUA_USE_MACOSX)
  set(PLATFORM_LIBS m)
elseif(WIN32)
  set(PLATFORM_LIBS)
endif()


# --- VM core source files (no frontend dependencies) ---
set(VM_CORE_SOURCES
  lapi.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c
  lmem.c lobject.c lopcodes.c lstate.c lstring.c ltable.c
  ltm.c lundump.c lvm.c lzio.c
)

# --- Standard library sources ---
set(VM_STDLIB_SOURCES
  lauxlib.c lbaselib.c ldblib.c liolib.c lmathlib.c loslib.c
  ltablib.c lstrlib.c lutf8lib.c loadlib.c lcorolib.c linit.c
)

# --- Frontend (compiler) sources ---
set(FRONTEND_SOURCES
  llex.c lparser.c lcode.c
)


# === Target 1a: libluavm (standalone VM shared library) ===
add_library(luavm SHARED ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm PUBLIC LUA_VM_ONLY)
target_include_directories(luavm PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(luavm ${PLATFORM_LIBS})
if(WIN32)
  # Export/import DLL symbols on Windows via LUA_BUILD_AS_DLL.
  # PUBLIC so that consumers (e.g. test_vm) automatically get __declspec(dllimport).
  target_compile_definitions(luavm PUBLIC LUA_BUILD_AS_DLL)
endif()
set_target_properties(luavm PROPERTIES
  VERSION ${PROJECT_VERSION}
  SOVERSION 5
  PUBLIC_HEADER "lua.h;luaconf.h;lualib.h;lauxlib.h;luavm.h"
)

# === Target 1b: libluavm_static (standalone VM static library) ===
add_library(luavm_static STATIC ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES})
target_compile_definitions(luavm_static PUBLIC LUA_VM_ONLY)
target_include_directories(luavm_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(luavm_static ${PLATFORM_LIBS})
set_target_properties(luavm_static PROPERTIES
  OUTPUT_NAME luavm
  PUBLIC_HEADER "lua.h;luaconf.h;lualib.h;lauxlib.h;luavm.h"
)


# === Target 2: liblua (full Lua library with frontend) ===
add_library(liblua STATIC
  ${VM_CORE_SOURCES} ${VM_STDLIB_SOURCES} ${FRONTEND_SOURCES}
)
target_include_directories(liblua PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(liblua ${PLATFORM_LIBS})
set_target_properties(liblua PROPERTIES OUTPUT_NAME lua)


# === Target 3: lua (full Lua interpreter) ===
add_executable(lua_exe lua.c)
target_link_libraries(lua_exe liblua ${PLATFORM_LIBS})
set_target_properties(lua_exe PROPERTIES OUTPUT_NAME lua)


# === Target 4: VM integration tests ===
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_vm.c)
  # Test linking against shared library
  add_executable(test_vm tests/test_vm.c)
  target_link_libraries(test_vm luavm ${PLATFORM_LIBS})

  # Test linking against static library
  add_executable(test_vm_static tests/test_vm.c)
  target_link_libraries(test_vm_static luavm_static ${PLATFORM_LIBS})
endif()


# === Install rules ===
install(TARGETS luavm luavm_static
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  PUBLIC_HEADER DESTINATION include/luavm
)
install(TARGETS lua_exe RUNTIME DESTINATION bin)
