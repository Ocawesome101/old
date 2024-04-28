-- filesystem driver --

local fs    = getStateEnv("lib")   or {}
local fstab = getStateEnv("fstab") or {
  path     = "/",
  node     = component.proxy(computer.getBootAddress()),
  children = {}
}
local mounts = getStateEnv("mounts") or {
  {
    path = "/",
    proxy = component.proxy(computer.getBootAddress())
  }
}

local split = getStateEnv("split") or function(path)
  checkArg(1, path, "string")
  local parts = {}
  for part in path:gmatch("[^\\/]+") do
    local current, up = part:find("^%.?%.$")
    if up == 2 then
      parts[#parts] = nil
    else
      parts[#parts + 1] = part
    end
  end
  return parts
end

local findNode = getStateEnv("findNode") or function(path, create, proxy, nocheck)
  checkArg(1, path, "string")
  checkArg(2, create, "boolean", "nil")
  if create then
    checkArg(3, proxy, "table")
  end
  checkArg(4, nocheck, "boolean", "nil")
  local currentNode  = fstab
  local currentIndex = 1
  local checkedNodes = {}
  local lastNode
  local lastSegment
  local pathSegments = split(path)
  while currentIndex <= #pathSegments do
    local currentSegment = pathSegments[currentIndex]
    checkedNodes[currentIndex] = currentNode
    if not currentNode.children[currentSegment] then
      if nocheck or currentNode.exists(table.concat(pathSegments, currentIndex)) then
        return currentNode, table.concat(pathSegments, currentIndex), lastNode, lastSegment
      elseif create then
        currentNode.children[currentSegment] = proxy
        mounts[#mounts + 1] = {
          path = path,
          proxy = proxy
        }
        return true
      else
        return nil, path .. ": no such file or directory"
      end
    else
      lastNode = currentNode
      lastSegment = currentSegment
      currentNode = currentNode.children[currentSegment]
    end
  end
end

setStateEnv("lib",      fs)
setStateEnv("fstab",    fstab)
setStateEnv("findNode", findNode)
setStateEnv("split",    split)
setStateEnv("mounts",   mounts)

if fs == {} then
  function fs.exists(file)
    checkArg(1, file, "string")
    local node, path = findNode(file)
    if not node then
      return nil, path
    end
    return true
  end

  function fs.canonical(path)
    checkArg(1, path, "string")
    return table.concat(segments(path), "/")
  end

  function fs.concat(...)
    local args = {}
    for i=1, #args, 1 do
      checkArg(i, args[i], "string")
    end
    return fs.canonical(table.concat(args, "/"))
  end

  function fs.get(file)
    checkArg(1, file, "string")
    local node, path = findNode(file)
    if not node then
      return nil, path
    end
    return node.proxy, path
  end

  function fs.mount(fs, path)
    checkArg(1, fs, "string", "table") -- the idea of proxy-based mountings makes things like a devfs much easier
    checkArg(2, path, "string")
    if type(fs) == "string" then
      fs = component.proxy(fs)
    end
    return find(path, true, fs)
  end

  function fs.umount(path)
    checkArg(1, path, "string")
    local node, path, parent, parentpath = findNode(path)
    if not node then
      return nil, path
    end
    parent.children[parentpath] = nil
    return true
  end

  function fs.list(path)
    checkArg(1, path, "string")
    local node, path = findNode(path)
    if not node then
      return nil, path
    end
    local files = node.proxy.list(path)
    return setmetatable(files, {__call = function()
      local tmp = next(files)
      if tmp then
        return tmp
      end
    end})
  end

  function fs.exists(path)
    checkArg(1, path, "string")
    local node, path = findNode(path)
    if not node then
      return nil, path
    end
    return node.proxy.exists(path)
  end

  function fs.isDirectory(path)
    checkArg(1, path, "string")
    local node, path = findNode(path)
    if not node then
      return nil, path
    end
    return node.proxy.isDirectory(path)
  end

  function fs.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    mode = mode or "r"
    local node, path = findNode(file)
    if not node then
      return nil, path
    end
    local handle = node.open(path)

    local wrap = {
      stream = handle,
      node   = node,
      closed = false
    }

    function wrap:read(amount)
      checkArg(1, amount, "number")
      if self.closed then
        return nil, "cannot read from closed file"
      end
      return self.node.read(self.stream, amount)
    end

    function wrap:readAll()
      local tmp = ""
      repeat
        local chk = self:read(math.huge)
        tmp = tmp .. (chk or "")
      until not chk
      return tmp
    end

    function wrap:write(data)
      checkArg(1, data, "string")
      return self.node.write(self.stream, data)
    end

    function wrap:close()
      self.closed = true
    end
  end

  function fs.findNode(path)
    checkArg(1, path, "string")
    local node, path = findNode(path)
    return node, path
  end

  fs.segments = split

  function fs.makeDirectory(file)
    checkArg(1, file, "string")
    local node, path = findNode(file, false, nil, true)
    if not node then
      return nil, path
    end
    return node.proxy.makeDirectory(path)
  end

  function fs.lastModified(file)
    checkArg(1, file, "string")
    local node, path = findNode(file)
    if not node then
      return nil, path
    else
      return node.proxy.lastModified(path)
    end
  end

  function fs.mounts()
    local tmp = {}
    for i=1, #mounts, 1 do
      tmp[#tmp + 1] = {
        path = mounts[i].path,
        address = mounts[i].proxy.address,
        label = mounts[i].proxy.getLabel()
      } 
    end
    return tmp
  end

  function fs.getLabel(path)
    checkArg(1, path, "string", "nil")
    path = path or "/"
    local node, path = findNode(path)
    if not node then
      return nil, path
    end
    return node.proxy.getLabel()
  end

  function fs.setLabel(label, path)
    checkArg(1, label, "string")
    checkArg(2, path, "string", "nil")
    path = path or "/"
    local node, path = findNode(path)
    if not node then
      return nil, path
    end
    return node.proxy.setLabel(label)
  end
end

while true do
  local data = {evtpull()}
  if data[1] == "ipc" then
    local from, oper = data[2], data[3]
    local resp = {}
    kernel.log(from, oper, data[4])
    if fs[oper] then
      resp = {fs[oper](table.unpack(data, 4))}
    else
      resp = {nil, "attempt to index field '" .. oper .. "' (a nil value)"}
    end
    ipcsend(from, table.unpack(resp))
  elseif data[1] == "component_added" and data[3] == "filesystem" then
    fs.makeDirectory("/mmt/" .. data[2]:sub(1, 3))
    fs.mount(data[2], "/mnt/" .. data[2]:sub(1,3))
  elseif data[1] == "component_removed" and data[3] == "filesystem" then
    local path = "/mnt/" .. data[2]:sub(1, 3)
    for i=1, #mounts, 1 do
      if mounts[i].proxy.address == data[2] then
        path = mounts[i].path
        break
      end
    end
    fs.umount(path)
  end
end
