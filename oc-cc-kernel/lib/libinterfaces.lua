-- A few miscellaneous interfacing utilities --

local errors = require("liberrors")

function dofile(file) -- Like require(), but you define the entire path.
  local ok, err = loadfile(file)
  if ok then setfenv(ok, _G); return ok() else
  errors.error(err) end
end

function tcopy(tbl) -- Return a copy of a table, rather than simply creating an "alias" of sorts.
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
  return rtn
end

function serialize(tbl) -- Convert a table to a nicely formatted string. Useful for writing tables to files.
  local rtn = "{\n"
  for i=1, #tbl, 1 do
    if type(tbl[i]) == "table" then
      rtn = rtn .. serialize(tbl[i])
    elseif type(tbl[i]) == "string" then
      rtn = rtn .. "  \"" .. tbl[i] .. "\""
      if i ~= #tbl then
        rtn = rtn .. ","
      end
      rtn = rtn .. "\n"
    end
  end

  rtn = rtn .. "}"
  
  return rtn
end

