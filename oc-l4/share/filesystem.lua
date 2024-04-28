-- fs lib --

local function callme(...)
  local r = {}
  ipcsend("drv/filesystem", r, ...)
  return table.unpack(r)
end

return setmetatable({}, {__index = function(tbl, k)
  return callme
end})
