-- CraftOS API implementation for OpenComputers --

-- INTERNAL: internal API --

local internal = {}
internal.sandbox = {
  _HOST = "OpenCraftOS 2"
  _CC_DISABLE_LUA51_FEATURES = true,
  gcinfo = function() return math.random(1,99999) end,
  assert = assert,
  tonumber = tonumber,
  load = function(x,m,e) return load(x,m,e or internal.sandbox) end,
  xpcall = xpcall,
  setmetatable = setmetatable,
  getmetatable = getmetatable,
  next = next,
  ipairs = ipairs,
  pairs = pairs,
  rawequal = rawequal,
  rawset = rawset,
  rawget = rawget,
  type = type
  select = select,
  loadstring = load, -- backwards compat
  pcall = pcall,
  error = error,
}

----------------------------

-- API: fs --

-- NOTE: I sandbox the user to /CraftOS because reasons.
-- /CraftOS/rom IS writable -- TODO fix

local mounts = {
  ["/"] = component.proxy(computer.getBootAddress())
}

function internal.createFSHandle(node, fd)
  local hand = {}
  function hand.read(num)
    return node.read(fd, num)
  end

  -- NOTE: this function is inefficient; especially slow for long lines.
  function hand.readLine()
    local ln = ""
    repeat
      local c = node.read(fd, 1)
      ln = ln .. (c or "")
    until c == "\n" or not c
    return (c:gsub("\n", ""))
  end

  function hand.readAll()
    node.seek(fd, "set")
    local dat = ""
    return dat
  end

  function hand.write(dat)
    checkArg(1, dat, "string")
    return node.write(fd, dat)
  end

  -- TODO: figure out what this is actually supposed to do
  function hand.writeLine(dat)
    return hand.write(dat)
  end

  -- STUB
  function hand.flush()end

  function hand.close()
    hand.closed = true
    node.close(fd)
    return true
  end
  return hand
end

function internal.mountDisk(addr)
  local n = disks[addr] or #disks + 1
  disks[n] = addr
  disks[addr] = n
  mounts["/CraftOS/disk"..(n>0 and n or "")] = component.proxy(addr)
end

function internal.unmountDisk(addr)
  local path = disks[addr] and ("/CraftOS/disk"..disks[addr])
  if path then
    mounts[path] = nil
  end
end

do
  local fs = {}

  local function split(p)
    local ss = {}
    for s in p:gmatch("[^/\\]+") do
      if s == ".." then
        table.remove(ss,#ss)
      else
        table.insert(ss,s)
      end
    end
    return ss
  end

  local function resolve(path, strict)
    local seg = split(path)
    table.insert(seg, 1, "CraftOS")
    for i=#seg, 1, -1 do
      local try = "/"..table.concat(seg, "/", 1, i)
      local ret = table.concat(seg, "/", i + 1)
      if mounts[try] then
        if mounts[try].exists(ret) or not strict then
          return mounts[try], ret
        end
      end
    end
    return nil, path .. ": no such file"
  end

  function fs.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string")
    local node, path = resolve(file, mode == 'r' or mode == 'rb' or mode == 'a')
    if not node then
      return nil, path
    end
    local fd, err = node.open(path, mode)
    if not fd then
      return nil, err
    end
    return internal.createFilesystemHandle(node, fd)
  end

  function fs.getName(path)
    checkArg(1, path, "string")
    local seg = split(path)
    return seg[#seg]
  end

  function fs.getDir(path)
    checkArg(1, path, "string")
    local seg = split(path)
    return table.concat(seg, "/", 1, #seg - 1)
  end

  function fs.makeDir(dir)
    checkArg(1, path, "string")
    local node, path = resolve(dir)
    if not node then
      return nil, path
    end
    return node.makeDirectory(path)
  end

  function fs.getCapacity(path)
    checkArg(1, path, "string")
    local node, err = assert(resolve(path))
    return node.spaceTotal()
  end

  function fs.getFreeSpace(path)
    checkArg(1, path, "string")
    local node, err = assert(resolve(path))
    return node.spaceTotal() - node.spaceUsed()
  end

  function fs.complete()
    return {}
  end

  function fs.combine(...)
    return (table.concat(table.pack(...), "/"):gsub("[^/\\]+", "/"))
  end

  function fs.copy()
    error("TODO: fs.copy")
  end

  function fs.move()
    error("TODO: fs.move")
  end

  function fs.attributes(path)
    checkArg(1, path, "string")
    local node, path = resolve(path, true)
    if not node then
      return nil, path
    end
    return {
      access = node.lastModified(path),
      created = node.lastModified(path),
      isDir = node.isDirectory(path),
      modification = node.lastModified(path),
      size = node.size(path)
    }
  end

  function fs.isReadOnly(path)
    checkArg(1, path, "string")
    local node, path = resolve(path)
    if not node then
      return nil, path
    end
    return node.isReadOnly()
  end

  function fs.isDriveRoot()
    return false
  end

  function fs.exists(f)
    checkArg(1, f, "string")
    local ok, err = resolve(f)
    return not not ok
  end

  function fs.list(path)
    checkArg(1, path, "string")
    local node, path = resolve(path, true)
    if not node or not node.isDirectory(path) then
      return nil, "Invalid directory"
    end
    -- TODO: filter out '/'s in directory listings
    return node.list(path)
  end

  internal.sandbox.fs = {}
end

-------------

-- API: colors --

do
  local colors = {
    white     = 0x1,
    orange    = 0x2,
    magenta   = 0x4,
    lightBlue = 0x8,
    yellow    = 0x10,
    lime      = 0x20,
    pink      = 0x40,
    gray      = 0x80,
    lightGray = 0x100,
    cyan      = 0x200,
    purple    = 0x400,
    blue      = 0x800,
    brown     = 0x1000,
    green     = 0x2000,
    red       = 0x4000,
    black     = 0x8000
  }

  internal.sandbox.colors = colors
end

-----------------

-- API: term --

internal.sandbox.term = {}

do
  local gpu, screen = component.proxy((component.list("gpu", true)())), component.list("screen", true)()
  local native = {} -- the native term object
  local nativePalette = {
    [0x1]     = 0xFFFFFF, -- white
    [0x2]     = 0xFF5500, -- orange
    [0x4]     = 0xEE00EE, -- magenta
    [0x8]     = 0x00BBFF, -- light blue
    [0x10]    = 0xFFFF00, -- yellow
    [0x20]    = 0x77FF00, -- lime
    [0x40]    = 0xFF00BB, -- pink
    [0x80]    = 0x707070, -- gray
    [0x100]   = 0xACACAC, -- light gray
    [0x200]   = 0x00FFFF, -- cyan
    [0x400]   = 0xAA00CC, -- purple
    [0x800]   = 0x0066FF, -- blue
    [0x1000]  = 0x995522, -- brown
    [0x2000]  = 0x00CC00, -- green
    [0x4000]  = 0xFF0000, -- red
    [0x8000]  = 0x000000  -- black
  }

  local palette = setmetatable({}, {__index = nativePalette})

  function native.nativePaletteColor(n)
    checkArg(1, n, "number")
    return assert(nativePalette[n], "invalid palette index")
  end

  local function pack(r,g,b)
    return bit32.lshift(r * 255 // 1, 16) + bit32.lshift(g * 255 // 1, 8) + (b * 255 // 1)
  end

  local function unpack(col)
    local r = bit32.rshift(col, 16)
    local g = bit32.rshift(col, 8) - bit32.lshift(r, 8)
    local b = col - bit32.lshift(bit32.rshift(col, 8), 8)
    return r / 255, g / 255, b / 255
  end

  function native.setPaletteColor(col, v1, v2, v3)
    checkArg(1, col, "number")
    checkArg(2, v1, "number")
    checkArg(3, v2, v2 and "number", "nil")
    checkArg(4, v3, v2 and "number", "nil")
    assert(palette[col], "invalid color")
    local color = v1 and v2 and v3 and pack(v1, v2, v3) or v1
    palette[col] = color
  end

  function native.getPaletteColor(col)
    return unpack(palette[col])
  end
end

---------------

-- API: peripheral --

internal.sandbox.peripheral = {}

---------------------

-- API: os --

internal.sandbox.os = {}

-------------

-- APIs: non-system from /CraftOS/rom/apis --

local files = internal.sandbox.fs.list("/rom/apis")
table.sort(files)
for i=1, #files, 1 do
  -- I don't use os.loadAPI because that is legacy crap and should die, though
  -- it somehow hasn't
  internal.sandbox.dofile("/rom/apis/"..files[i])
end

---------------------------------------------

-- INTERNAL: run shell and rednet --



------------------------------------
