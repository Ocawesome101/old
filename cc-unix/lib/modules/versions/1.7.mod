-- Attempt to fix things on CC1.7 --

local unpack = function(tbl, i)
  local i = i or 1
  return tbl[i], unpack(tbl, i+1)
end

table.unpack = function(tbl)
  return unpack(tbl)
end
