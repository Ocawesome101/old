-- OpenFS parser. Will ONLY work on unmanaged drives. --

local drive = component.list("drive")()
if not drive then
  error("No unmanaged drives found")
end
drive = component.proxy(drive)

local tbl = ""
for i=0x000010, 0x00FFFF, 0x000001 do
  tbl = tbl .. string.char(drive.readByte(i))
end
local ok, err = load("return " .. tbl, "=openfs.masterTable", "bt", _G)
if not ok then
  error(err)
end

local master = ok()

local function split(str, sep)
  checkArg(1, str, "string")
  local sep = sep or " "
  local words = {}
  local word = ""
  for char in str:gmatch(".") do
    if char == sep then
      if word ~= "" then
        table.insert(words, word)
      end
    else
      word = word .. char
    end
  end
  if word ~= "" then
    table.insert(words, word)
  end
  return words
end

local function lookup(filename)
  local function resolve(nodes, file)
    for k,v in pairs(nodes) do
      if k == file then
        return v
      elseif v.subNodes then
        return resolve(v.subNodes, file)
      end
    end
  end
  return resolve(master, filename)
end

local function lastUsed()
  local lastUsedByte = 0x00FFFF
  local function resolve(node)
    for k,v in pairs(node) do
      if k == filename then
        return false
      end
      if v.type == "file" then
        lastUsedByte = v.startOffset + v.size
      else
        resolve(v.subNodes)
      end
    end
  end
  return lastUsed
end

local function makefile(filename, filetype)
  local lastUsed = lastUsed
  master[filename] = {
    type = filetype,
    startOffset = lastUsed + 1,
    size = 1
  }
end

local function alloc(offset, size) -- Move data out of the way, starting with
  local current = offset + size
  local function moveByte(o1, o2)
    local b = drive.readByte(o1)
    drive.writeByte(o2, b)
  end
  for i=current, size, -1 do
    moveByte(i, i + size)
  end
end

local function write(data, offset)
  alloc(offset, #data)
  for i=1, #data, 1 do
    drive.writeByte(i + offset, data:sub(i, i):byte())
  end
end

local function serialize(tbl)
  local rtn = "{"
  for k, v in pairs(tbl) do
    rtn = rtn .. tostring(k) .. "="
    if type(v) == "table" then
      rtn = rtn .. serialize(v)
    else
      rtn = rtn .. v
    end
    rtn = rtn .. ","
  end
  return rtn
end

_G.openfs = {}

function openfs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string")
  local fileData = lookup(file)
  local mode = mode or "r"
  if not fileData and mode ~= "w" then
    return false, "File not found"
  end
  if not fileData and mode == "w" then
    fileData = {}
  end
  
  fileData.startOffset = fileData.startOffset or lastUsed() + 1
  local offset = fileData.startOffset
  local size = fileData.size
  local handle = {}
  local position = offset
  if mode == "r" or mode == "a" or mode == "rw" then
    function handle:read(amount)
      local data = ""
      local amount = amount
      if position + amount > offset + size then
        amount = offset + size - position
      end
      for i=position, position+amount, 1 do
        data = data .. string.char(drive.readByte(i))
      end
      position = position + amount
      if position >= offset + size then
        handle = nil
      end
      return data
    end
  end
  if mode == "w" or mode == "a" or mode == "rw" then
    function handle:write(data)
      size = size + #data
      alloc(offset, size)
      local current = size - #data
      for i=1, #data, 1 do
        drive.writeByte(current, data:sub(i,i):byte())
        current = current + 1
      end
    end
  end
  function handle:close()
    handle = nil
  end
  return handle
end

function openfs.remove(file)
  checkArg(1, file, "string")
end
