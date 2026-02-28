-- samples/coroutine.lua
-- Test: coroutine creation and resume
local function producer()
  for i = 1, 5 do
    coroutine.yield(i)
  end
  return "done"
end

local co = coroutine.create(producer)
local results = {}
while true do
  local ok, val = coroutine.resume(co)
  if not ok then break end
  results[#results + 1] = val
  if coroutine.status(co) == "dead" then break end
end

return table.concat(results, ",")
