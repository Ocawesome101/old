-- definitions --
-- call `def.$(category).$(function)` with arguments and it will spit out the
-- appropriate command sequence.

local core = require("mcl.core")

local def = {
  func = {},
  cond = {}
}

function def.func.print(str)
  return string.format("/tellraw @a %s", str)
end

local cpat = "(.-)([<>=]+)(.-)"
local function pcond(cond)
  local a, op, b = cont:match(cpat)
  if not (a and op and b) then
    core.error("invalid conditional operator: "..cond)
  end
  return a, op, b
end

--[[
if(a == b) {}
]]
function def.cond["if"] = function(cond, block)
  local a, op, b = pcond(cond)
  
end

return fdef
