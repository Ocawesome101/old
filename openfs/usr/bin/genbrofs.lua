-- create a BROFS --

local args = {...}

local out = "brofs.bin"

local fs = require("filesystem")
local path = args[1] or "/usr/lib/brofs/"

local handle = io.open(out, "w")

local ftable = ""
local fdata = ""

local last = 3
local function addTableFile(file, size)
  print("adding file " .. file .. " with size " .. size .. " (" .. math.ceil(size / 512) .. " sectors)")
  ftable = ftable .. string.pack("<I2I2I2I1I1c24", last, size, math.ceil(size / 512) * 512, 1, 1, file:sub(1,24))
  last = last + math.ceil(size / 512)
end

for file in fs.list(path) do
  local full = fs.concat(path, file)
  addTableFile(file, fs.size(file))
  local handle = io.open(file, "r")
  fdata = fdata .. handle:read("*a")
  handle:close()
end

print("saving data")
handle:write(string.pack("c2048", ftable) .. fdata)
handle:close()
