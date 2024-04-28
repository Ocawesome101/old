local prox = component.proxy(computer.getBootAddress())
loadfile = function(file)
  local handle = assert(prox.open(file, "r"))
  local data = ""
  while true do
    local chunk = prox.read(handle, math.huge)
    if not (chunk) then
      break
    end
    data = data .. chunk
  end
  prox.close(handle)
  return load(data, "=" .. file, "bt", _G)
end
local x = assert(loadfile("/stream/core.lua"))
return x()
