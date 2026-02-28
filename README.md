# Lua

This is the repository of Lua development code, as seen by the Lua team. It contains the full history of all commits but is mirrored irregularly. For complete information about Lua, visit [Lua.org](https://www.lua.org/).

Please **do not** send pull requests. To report issues, post a message to the [Lua mailing list](https://www.lua.org/lua-l.html).

Download official Lua releases from [Lua.org](https://www.lua.org/download.html).

## Project Structure

```
├── src/          # C source files and headers
├── tests/        # Integration tests
├── testes/       # Lua test suite
├── samples/      # Sample Lua scripts and bytecode
├── docs/         # Documentation
├── manual/       # Lua reference manual
├── CMakeLists.txt
├── makefile
└── README.md
```

## Building

### Using CMake

```bash
mkdir build && cd build
cmake ..
make
```

### Using Make

```bash
make
```
