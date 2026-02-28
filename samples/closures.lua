-- samples/closures.lua
-- Test: closures and upvalues
local function make_counter(start)
  local count = start
  return function()
    count = count + 1
    return count
  end
end

local counter = make_counter(0)
return counter(), counter(), counter()
