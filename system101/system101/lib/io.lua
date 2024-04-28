-- io.lua --

local buffer = require("buffer")
local filesystem = require("filesystem")

local io = {}

function io.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  local handle, err = filesystem.open(file, mode)
  if not handle then
    return nil, err
  end
  return buffer.new(handle, mode)
end

-- sure, let's define this here
function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  local handle, err = io.open(file, "r")
  if not handle then
    return nil, err
  end
  local data = handle:read("a")
  handle:close()
  return load(data, "="..file, mode or "bt", env or _G)
end

return io
