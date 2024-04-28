-- generate an OpenFS image --

local pack = "<c32I1I8I3c15c440I4"

local out = io.open("openfs.bin", "w")

local function _()
  local t = {}
  for i=3,129,1 do t[#t+1]=i end
  return table.unpack(t)
end

out:write(string.pack("<" .. string.rep("I4", 128), 1, 0, _()) .. string.pack(pack, "/", 1, os.time(), 0xFFFFFF, "root", "", 0))

out:close()

print("Saved image to openfs.bin")
