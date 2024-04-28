-- OpenFS driver --

local inodePattern = "<c32I1I8I3c15c440I4"

local openfs = {}

local types = {
  file = 0,
  directory = 1,
  link = 2
}

local function readSector(pd, dr, sc)
  local r = pd.Start + sc - 1
  if r > pd.End or r < pd.Start then
    error("attempt to read sector " .. r .. " out of partition bounds")
  end
  print("READ SECTOR " .. (r or "NIL"))
  return dr.readSector(r)
end

local function writeSector(pd, dr, sc, dt)
  local w = pd.Start + sc - 1
  if w > pd.End or w < pd.Start then
    error("attempt to write sector " .. r .. " out of partition bounds")
  end
  print("WRITE SECTOR " .. (w or "NIL") .. ": " .. dt)
  return dr.writeSector(w, dt)
end

local function unpackPointers(pt, mr, dr, pd)
  local pointers = {}
  local pattern = "<" .. string.rep("I4", #pt / 4)
  for _, pointer in ipairs(table.pack(string.unpack(pattern, pt))) do
    if pointer == 0 then break end
    table.insert(pointers, pointer)
  end
  if mr > 0 then
    for _, pointer in ipairs(unpackPointers(string.unpack("<c508I4", readSector(pd, dr, mr)), dr, pd)) do
      if pointer == 0 then break end
      table.insert(pointers, pointer)
    end
  end
  return pointers
end

local function parseInode(nd, dr, pd)
  local fname, ftype, lmod, perms, owner, pointers, more = string.unpack(inodePattern, nd)
  print(fname, ftype, lmod, perms, owner, pointers, more)
  return {
    name = fname:gsub("\0", ""), -- not sure if unpack does this
    type = ftype,
    lastModified = lmod,
    permissions = perms,
    owner = owner:gsub("\0", ""), -- ^^^
    pointers = unpackPointers(pointers, more, dr, pd)
  }
end

local function split(fp)
  checkArg(1, fp, "string")
  local seg = {}
  for segment in fp:gmatch("[^\\\n/]+") do
--    print(segment)
    if segment == ".." then
--      print("IS DOT-DOT")
      seg[#seg] = nil
    elseif segment ~= "." then
--      print("IS NOT DOT")
      seg[#seg + 1] = segment
    end
  end
  table.insert(seg, 1, "/")
--  print('/' ..table.concat(seg, "/"))
  return seg
end

-- very inefficiently and possibly unreliably find free sectors
local function findFreeSector(pd, dr, st)
  for i=st or 3, pd.End - pd.Start, 1 do
    local sect = readSector(pd, dr, i)
    if sect:sub(1,1) == "\0" then
      return i
    end
  end
  error("no free sectors found after offset " .. (st or 3))
end

local function findFree(pd, dr, fc)
  if #fc > 0 then
    return table.remove(fc, 1)
  else
    for i=1, 126, 1 do
      fc[i] = findFreeSector(pd, dr, fc[i] or 2)
    end
    return table.remove(fc, 1)
  end
end

-- pack pointers, and write any trailing ones to disk
local function packPointers(pd, dr, pt, fc)
  local write, more = {}, 0
  for i=1, #pt, 1 do
    local new = string.pack("<I4", pt[i])
    table.insert(write, new)
  end
  local ret = table.concat(write, "", 1, (#write >= 110 and 110) or #write)
  if #write > 110 then
    local new = findFree(pd, dr, fc)
    more = new
    for i=111, #write, 127 do
      print("write pointers to " .. new)
      local wrt = string.pack("<c508I4", table.concat(write, "", i, i + 127), new)
      writeSector(pd, dr, new, wrt)
      new = findFree(pd, dr, fc)
    end
  end
  return ret, more
end

local function findFile(pd, dr, fl, fd)
  local root = readSector(pd, dr, 2)
  local data = parseInode(root, dr, pd)
  fd["/"] = fd["/"] or 2
  if fd[fl] then return parseInode(readSector(pd, dr, fd[fl])) end
  local segments = split(fl)
  local function find(ind, i, N)
    local search = segments[i] or (i == 1 and "/")
    if not search then return nil, "segment is nil?? i-value: " .. i .. ", inode: " ..N end
    if i == #segments then
      if ind.name == search then
        fd[fl] = N
        return ind, N
      else
        return nil, "file not found"
      end
    else
      fd["/" .. table.concat(split(fl), "/", 1, i)] = N
      if ind.type == types.file then
        return nil
      else
        for _, c in ipairs(ind.children or {}) do
          local n, e = find(parseInode(readSector(pd, dr, c), dr, pd), i + 1, c)
          if n then
            return n, c
          end
        end
      end
    end
  end
  local dat, err = find(data, 1, 1)
  if not dat then
    return nil, err
  end
  return parseInode(dat, dr, pd), err
end

function openfs.new(partdata, address, drive)
  local found = {}
  local free = {}

  local fsc = {type = "filesystem", address = address}

  local label = "OpenFS"

  function fsc.exists(file)
    checkArg(1, file, "string")
    local node, err = findFile(partdata, drive, file, found)
    if node then
      return true
    else
      return false
    end
  end

  function fsc.getLabel()
    return label
  end

  function fsc.setLabel(lbl)
    checkArg(1, lbl, "string")
    label = lbl:sub(1, 32)
    return label
  end

  function fsc.isReadOnly()
    return false
  end

  function fsc.list(dir)
    checkArg(1, dir, "string")
    local node, err = findFile(partdata, drive, dir, found)
    if not node then
      return nil, err
    end
    local files = {}
    for _, num in ipairs(node.children) do
      -- directly parse inodes since it's faster (and easier!) than looking up each file with calls to isDirectory().
      local data = parseInode(readSector(partdata, drive, num), drive, partdata)
      local name = data.name
      if data.type == types.directory then
        name = name .. "/"
      end
      files[#files + 1] = name
    end
    return files
  end

  function fsc.isDirectory(dir)
    checkArg(1, dir, "string")
    local node, err = findFile(partdata, drive, dir, found)
    if not node then
      return nil, err
    end
    return node.type == types.directory
  end

  function fsc.makeDirectory(dir)
    checkArg(1, dir, "string")
    local path, make = dir:match("(.+)/(.+)")
    path, make = path or "/", make or dir
    local node, err = findFile(partdata, drive, path, found)
    if not node then
      return nil, err
    end
    print(node.name, node.type, node.lastModified, node.owner)
    local new, seg = findFree(partdata, drive, free), err
    if path == "/" then seg = 1 end
    node.pointers[#node.pointers + 1] = new
    writeSector(partdata, drive, new, string.pack(inodePattern, make, types.directory, os.time(), 0xFFFFFF, "root", "", 0))
    writeSector(partdata, drive, seg, string.pack(inodePattern, node.name, types.directory, node.lastModified, node.permissions, node.owner, packPointers(partdata, drive, node.pointers, free)))
    return true
  end

  return fsc
end

return openfs
