--[[
  openfslib.lua
  Library to read and write to OpenFS filesystems

  This file is part of the OpenBootLoader project
  https://github.com/Ocawesome101/OpenBootLoader
  (C) 2020 Ocawesome101, under the MIT license.
]]

local opfs = {}
local fs = {}
fs.address = address
fs.type = "filesystem"

local ftypes = {
  file = 0,
  dir  = 1,
  link = 2
}

function fs:readSector(sect)
  local s = sect + self.partdata.Start
  if s > self.partdata.End then
    return nil, "sector pointer out of partition bounds"
  end
  return self.drive.readSector(s)
end

function fs:writeSector(sect, data)
  local s = sect + self.partdata.Start
  if s > self.partdata.End then
    return nil, "sector pointer out of partition bounds"
  end
  return self.drive.writeSector(s, data)
end

function fs:readSectors(start, number)
  local d = ""
  for i=start, start+number, 1 do
    d = d .. (fs:readSector(i) or "")
  end
  return d
end

-- Copied from the OpenOS fs lib
local function split(path)
  local parts = {}
  for part in path:gmatch("[^\\/]+") do
    local current, up = part:find("^%.?%.$")
    if current then
      if up == 2 then
        table.remove(parts)
      end
    else
      table.insert(parts, part)
    end
  end
  return parts
end

local function getName(file)
  local segments = split(file)
  return segments[#segments]
end

function fs:parseInode(data)
  checkArg(1, data, "string")
  local fname, ftype, fmodified, fperms, fowner, fdata, fmore = string.unpack("<c32 I1 I8 I3 c15 c440 I4")
  local dataSectors = {string.unpack( "<" .. ("I4"):rep(110), fdata)}
  while fmore > 0 do
    local sectorData = self:readSector(fmore)
    local moreDataSectors = {string.unpack( "<" .. ("I4"):rep(128), sectorData)}
    if moreDataSectors[128] == fmore and fmore ~= 0 then
      error("inode recursion loop detected at sector " .. fmore)
    end
    fmore = moreDataSectors[128]
    for i=1, 127, 1 do
      if moreDataSectors[i] == 0 then
        break
      end
      table.insert(dataSectors, moreDataSectors[i])
    end
  end
  return fname, ftype, fmodified, fperms, fowner, dataSectors
end

function fs:findFile(file) -- recursively scan the files table and its subdirectories for a file inode. Probably slow.
  self.found = self.found or {}
  if self.found[file] then
    return self.found[file]
  end
  local rootInode = self.readSector(self, 2)
  local rname, rtype, rmodified, rperms, rowner, rfiles = self:parseInode(rootInode)
  local function find(files, f)
    for i=1, #files, 1 do
      local inode, err = self:readSector(files[i])
      if not inode then
        return nil, err
      end
      local n, t, m, p, o, d = self:parseInode(inode)
      if n == f then
        return files[i], n, t, m, p, o, d
      end
    end
    return nil, "no such file or directory"
  end
  local seg = split(file)
  local c = rfiles
  for i=1, #seg, 1 do
    local inode, name, ftyp, mod, perms, owner, data = find(c, seg[i])
    if not inode then
      return false
    else
      self.found[table.concat(seg, "/", 1, i)] = {inode, name, ftyp, mod, perms, owner, data}
      if i == #seg then
        return inode, name, ftyp, mod, perms, owner, data
      end
    end
  end
end

function fs:exists(file)
  checkArg(1, file, "string")
  local fdata = self:findFile(file)
  if fdata then
    return true
  else
    return false
  end
end

function fs:isDirectory(file)
  checkArg(1, file, "string")
  local inode, name, ftyp = self:findFile(file)
  if not inode then
    return nil, name
  end
  return ftyp == ftypes.dir
end

local open = {}

function fs:open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  mode = mode or "r"
  if not self:exists(file) then
    return nil, file
  end
  if self:isDirectory(file) then
    return nil, "cannot edit a directory"
  end
  local _, _, _, _, _, _, inodes = findFile(file)
  local handle = {
    ptr = 1,
    inodes = inodes,
    mode = {}
  }
  for char in mode:gmatch('.') do
    handle.mode[char] = true
  end
  handle.mode.w = handle.mode.a
  local i = #open + 1
  open[i] = handle
  return i
end

function fs:read(handle, amount)
  checkArg(1, handle, "number")
  checkArg(2, amount, "number")
  if amount == math.huge then amount = 2048 end
  if not open[handle] then
    return nil, "invalid handle"
  end
  local h = open[handle]
  local inode = math.ceil(h.ptr / 508)
  local inodes = math.ceil(amount / 508)
  local read = ""
  for i=inode, inode+inodes, 1 do
    local data = self:readSector(h.inodes[i])
    read = read .. (data:sub(5) or "")
  end
  return read:sub(1, amount):gsub("\0", "")
end

function fs:write(handle, data)
  checkArg(1, handle, "number")
  checkArg(2, data, "string")
  if not open[handle] then
    return nil, "invalid handle"
  end
  if not open[handle].mode.a then
    return nil, "overwriting not yet supported"
  end
  local h = open[handle]
  local ptr = h.ptr
  local inode = h.inodes[ptr // 508]
  local read = self:readSector(inode):gsub("\0", "")
  self:writeSector(inode, read .. data:sub(1, 508 - #read))
  if (512 - #read) >= #data then
    return true
  end
  local chunks = {}
  for i=1, #data, 512 do
    chunks[#chunks + 1] = data:sub(i, i + 511)
  end
  local offset = 0
  for i=inode + 1, inode + #chunks, 1 do
    local function check()
      local data = self:readSector(i + offset)
      local parentInode = string.unpack("<I4c508", data)
      if parentInode and parentInode ~= h.inode then
        offset = offset + 1
        if i + offset > self.drive.getCapacity()/512 then
          error("drive is full")
        end
        return check()
      end
      return true
    end
    check()
    for i=1, #h.inodes, 1 do
      if h.inodes[i] == i + offset then break end
    end
    local ok, err = self:writeSector(i + offset, string.pack("<I4c508", chunks[i] .. ("\0"):rep(508 - #chunks[i])))
    if not ok then
      error(err)
    end
  end
  return true
end

function fs:seek(handle, whence, offset)
  checkArg(1, handle, "number")
  checkArg(2, whence, "string")
  checkArg(3, offset, "number")
  return nil, "seeking not implemented" -- it will have to come at some point, but for now I don't wanna figure out the logic of writing to the beginning or middle of a file
end

function fs:close(handle)
  checkArg(1, handle, "number")
  open[handles] = nil
end

local function parsePermissions(byte)
  local r, w, x = byte & 48, byte & 12, byte & 3
  if r == 48 then
    r = true
  else
    r = false
  end
  if w == 12 then
    w = true
  else
    w = false
  end
  if x == 3 then
    x = true
  else
    x = false
  end
  return r, w, x
end

function fs:permissions(file) -- POSIX (I think) permissions
  checkArg(1, file, "string")
  local inode, name, ftyp, mod, perms, owner, data = self:findFile(file)
  if not inode then
    return nil, name
  end
  local _owner, _group, _other = string.unpack("<I1I1I1", string.pack("<I3", perms))
  return {parsePermissions(_owner)}, {parsePermissions(_group)}, {parsePermissions()}
end

function fs:list(dir)
  checkArg(1, dir, "string")
  local inode, name, ftyp, mod, perms, owner, data = self:findFile(file)
  if not inode then
    error(err)
  end
  if ftyp ~= ftypes.dir then
    return nil, "not a directory"
  end
  local files = {}
  for i=1, #data, 1 do
    local inode = self:readSector(data[i])
    local name, ftyp = self:parseInode(inode)
    local fent = name
    if ftyp == ftypes.dir then
      fent = fent .. "/"
    end
    files[#files + 1] = fent
  end
  return files
end

function fs:size(path)
  checkArg(1, path, "string")
  local inode, name, ftyp, mod, perms, owner, data = self:findFile(path)
  if not inode then
    return nil, name
  end
  if ftyp == ftypes.dir then
    return 512
  end
  return #data * 512 + 512
end

function fs:spaceUsed()
  local total = 512
  local function recurse(dir)
    local files = self:list(dir)
    for i=1, #files, 1 do
      if files[i]:sub(-1) == "/" then
        recurse(dir .. files[i])
      end
      total = total + self:size(dir .. files[i])
    end
  end
  recurse("/")
  return total
end

local function getPath(p)
  local segments = split(p)
  return table.concat(segments, "/", 1, #segments - 1)
end

function fs:makeDirectory(path)
  checkArg(1, path, "string")
  local gp = path
  while not self:exists(getPath(gp)) do
    self:makeDirectory(getPath(gp))
    gp = getPath(gp)
  end
  gp = getPath(path)
  local inode, name, ftyp, mod, perms, own, data = self:findFile(gp)
  local created = self:findFreeInode()
  self:writeSector(self:makeInode(getName(path), ftypes.dir, perms, own))
  data[#data + 1] = created
end

function fs:isReadOnly()
  return false
end

function fs:getLabel()
  return "label_placeholder"
end

function opfs.new(partdata, address, drive)
  checkArg(1, partdata, "table")
  checkArg(2, address, "string")
  checkArg(3, drive, "table")

  local new = {data=partdata, partdata=partdata, address=address, drive=drive}
  return setmetatable(new, {__index=function(tbl, k) if not fs[k] then return nil end return function(...) return fs[k](new, ...) end end})
end

return opfs
