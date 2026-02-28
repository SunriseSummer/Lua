-- samples/tables.lua
-- Test: table creation and operations
local t = {1, 2, 3, "four", "five"}
local sum = 0
for i = 1, 3 do
  sum = sum + t[i]
end

local map = {name = "Lua VM", version = 5.5}
return sum, map.name, map.version
