-- OpenUPT driver. Might as well make it as solid as I can so I can use it everywhere :P --

local component = require("component") -- This line is probably the only one that will really ever need to be changed

local upt = {}

local bootSector = 1

local bootLoaderStart = 2
local bootLoaderEnd = 24

local partitionTable = 25

local dataStart = 33

local currentDrive = ""
local currentPartitionTable = {}

local defaultBootSector = [[local l,i=component.list,component.invoke
local g,s=l("gpu")(),l("screen")()
i(g,"bind",s)
local w,h=i(g,"getResolution")
i(g,"fill",1,1,w,h," ")
i(g,"set",1,1,"Non-system disk or disk error")
computer.beep(440, 1)
while true do computer.pullSignal()end]]

local function toHex(g)
  checkArg(1, g, "string")
  local h = ""
  for char in g:gmatch(".") do
    h = h .. string.format("%02x", char:byte())
  end
  return h
end

local function generateUUID()
  local s = {4,2,2,2,6}
  local addr = ""
  local p = 0

  for _,_s in ipairs(s) do
    if #addr > 0 then
      addr = addr .. "-"
    end
    for _=1, _s, 1 do
      local b = math.random(0, 255)
      if p == 6 then
        b = (b & 0x0F) | 0x40
      elseif p == 8 then
        b = (b & 0x3F) | 0x80
      end
      addr = addr .. ("%02x"):format(b)
      p = p + 1
    end
  end
  return addr
end

local function getGUID()
  local g = ""
  for i=1, 8, 1 do
    g = g .. string.char(math.random((i == 0 and 1) or 0, 255))
  end
  return g
end

-- kind of a hack but w/e
function upt.new(id, driver)
  if #currentPartitionTable == 0 then
    upt.readPartitions()
  end
  local partdata = currentPartitionTable[id] or error("no such partition")
  return driver.new(partdata, generateUUID(), component.proxy(currentDrive))
end

function upt.readPartitions()
  local _ptable = component.invoke(currentDrive, "readSector", partitionTable)
  local ptable = {}
  for i=1, #_ptable, 64 do
    local part = _ptable:sub(i, i + 63)
    local pstart, pend, ptype, pflags, guid, label = string.unpack("<I4I4c8I4c8c36", part)
    if guid:sub(1,1):byte() == 0 then
      break
    end
    ptable[#ptable + 1] = {
      Start = tonumber(pstart),
      End = pend,
      Type = ptype,
      Flags = pflags,
      GUID = guid,
      Label = label
    }
  end
  currentPartitionTable = ptable
end

function upt.writePartitions()
  local ptable = ""
  for i=1, #currentPartitionTable, 1 do
    local t = currentPartitionTable[i]
    local s, e, t, f, g, l = t.Start, t.End, t.Type, t.Flags, t.GUID, t.Label
    --print(s, e, t, g, g, l)
    ptable = ptable .. string.pack("<I4I4c8I4c8c36", s, e, t, f, g, l)
  end
  ptable = string.pack("<c512", ptable)
  component.invoke(currentDrive, "writeSector", partitionTable, ptable)
end

function upt.getPartitions()
  local p = {}
  for i=1, #currentPartitionTable, 1 do
    local cur = currentPartitionTable[i]
    p[i] = {
      start = cur.Start,
      ["end"] = cur.End,
      type = cur.Type,
      flags = cur.Flags,
      guid = toHex(cur.GUID),
      label = cur.Label
    }
  end
  return p
end

function upt.addPartition(ps, pe, pt, pl)
  checkArg(1, ps, "number")
  checkArg(2, pe, "number")
  checkArg(3, pt, "string")
  checkArg(4, pl, "string", "nil")
  if ps < 33 then
    print("NOTE: shifting partition forward " .. 33 - ps .. " sectors")
    local s = 33 - ps
    ps = ps + s
    pe = pe + s
    print("NOTE: new partition starts at " .. ps .. ", ends at " .. pe)
  end
  pt = pt:upper()
  pl = pl or generateUUID()
  for i=1, #currentPartitionTable, 1 do
    local _ps, _pe = currentPartitionTable[i].Start, currentPartitionTable[i].End
    if (_ps <= pe and _ps > ps) --[[or ()]] then
      return nil, "end sector overlaps with partition " .. i
    elseif (ps < _pe and ps > _ps) --[[or ()]] then
      return nil, "start sector overlaps with partition " .. i
    end
  end
  if #currentPartitionTable == 8 then
    return nil, "partition table is full"
  end
  currentPartitionTable[#currentPartitionTable + 1] = {
    Start = ps,
    End   = pe,
    Type  = pt,
    Flags = 0,
    GUID  = getGUID(),
    Label = pl
  }
  return true
end

function upt.delPartition(i)
  checkArg(1, i, "number")
  if not currentPartitionTable[i] then
    return nil, "no such partition"
  end
  currentPartitionTable[i] = nil--[[{
    Start = "",
    End = "",
    Type = "",
    Flags = 0,
    GUID = string.char(0),
    Label = ""
  }]]
  return true
end

function upt.select(address)
  checkArg(1, address, "string")
  if currentDrive ~= "" then
    upt.writePartitions()
  end
  if component.type(address) ~= "drive" then
    return nil, "bad component address (expected drive, got " .. component.type(address) .. ")"
  end
  currentDrive = address
  upt.readPartitions()
  return true
end

function upt.format(bootsector, erase)
  checkArg(1, bootsector, "string", "nil")
  local b = bootsector or defaultBootSector
  local sectors = component.invoke(currentDrive, "getCapacity") / 512
  component.invoke(currentDrive, "writeSector", partitionTable, string.char(0):rep(512))
  if erase then
    io.write("erasing drive....      ")
    for i=1, sectors, 1 do
      local percent = (100 * i) // sectors .. "%"
      io.write(string.format("\27[%dD", #percent) .. percent)
      component.invoke(currentDrive, "writeSector", i, string.char(0):rep(512))
    end
    io.write("\nDone.\n")
  end
  currentPartitionTable = {}
  print("Writing boot sector....")
  component.invoke(currentDrive, "writeSector", bootSector, b .. (" "):rep(512 - #b))
  print("Done.")
end

function upt.bootsector(b)
  checkArg(1, b, "string")
  if not load(b,"=bootsector","bt",_G) then
    return nil, "bootsector is not executable"
  end
  if #b > 512 then
    return nil, "bootsector is too large: " .. #b .. " > 512"
  end
  return component.invoke(currentDrive, "writeSector", bootSector, b .. (" "):rep(512 - #b))
end

function upt.bootloader(b)
  checkArg(1, b, "string")
  if #b > 12058624 then
    return nil, "bootloader is too large"
  end
  if not load(b,"=bootloader","bt",_G) then
    return nil, "bootloader is not executable"
  end
  for i=bootLoaderStart, bootLoaderEnd, 1 do
    local sect = b:sub((i - (bootLoaderStart)) * 512, ((i - (bootLoaderStart)) + 1) * 512)
    sect = sect .. (" "):rep(512 - #sect)
    component.invoke(currentDrive, "writeSector", i, sect)
  end
  return true
end

-- copy raw data to a partition
function upt.flashpart(id, data)
  checkArg(1, id, "number")
  checkArg(2, data, "string")
  if not currentPartitionTable[id] then
    return nil, "no such partition"
  end
  local part = currentPartitionTable[id]
  if part.End - part.Start < #data then
    return nil, "image is too big"
  end
  local i = part.Start
  for chunk in data:gmatch(string.rep(".",512)) do
    component.invoke(currentDrive, "writeSector", i, chunk)
    i = i + 1
  end
end

upt.select(component.list("drive", true)())

return upt
