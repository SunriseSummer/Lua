-- samples/strings.lua
-- Test: string operations
local s = "Hello, World!"
local upper = string.upper(s)
local len = #s
local sub = string.sub(s, 1, 5)
local rep = string.rep("ab", 3)
local fmt = string.format("x=%d y=%.2f", 42, 3.14)
return upper, len, sub, rep, fmt
