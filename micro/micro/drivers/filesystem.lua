-- fs drivers --

local component, computer = component, computer
local rootfs = component.proxy(computer.getBootAddress())

local mounts = {
  {
    path = "/",
    proxy = rootfs
  }
}

local function split(s, ...)
  checkArg(1, s, "string")
  local rw = {}
  local _s = table.concat({...}, s)
  for w in _s:gmatch("[^%" .. s .. "]+") do
    rw[#rw + 1] = w
  end
  local i=1
  setmetatable(rw, {__call = function()
    i = i + 1
    if rw[i - 1] then
      return rw[i - 1]
    else
      return nil
    end
  end
  })
  return rw
end

local function clean(p)
  checkArg(1, p, "string")
  local path = ""
  for segment in p:gmatch("[^%/]+") do
    path = path .. "/" .. (segment or "")
  end
  if path == "" then
    path = "/"
  end
  return path
end

local function resolve(path) -- Resolve a path to a filesystem proxy
  checkArg(1, path, "string")
  local proxy
  local path = clean(path)
  for i=1, #mounts, 1 do
    if mounts[i] and mounts[i].path then
      local pathSeg = clean(path:sub(1, #mounts[i].path))
      if pathSeg == mounts[i].path then
        path = clean(path:sub(#mounts[i].path + 1))
        proxy = mounts[i].proxy
      end
    end
  end
  if proxy then
     return clean(path), proxy
  end
end

local fs = {}

function fs.mount(addr, path)
  checkArg(1, addr, "string")
  checkArg(2, path, "string", "nil")
  local label = component.invoke(addr, "getLabel")
  label = (label ~= "" and label) or nil
  local path = path or "/mount/" .. (label or addr:sub(1, 6))
  path = cleanPath(path)
  local p, pr = resolve(path)
  for _, data in pairs(mounts) do
    if data.path == path then
      if data.proxy.address == addr then
        return true, "Filesystem already mounted"
      else
        return false, "Cannot override existing mounts"
      end
    end
  end
  if component.type(addr) == "filesystem" then
    if fs.makeDirectory then
      fs.makeDirectory(path)
    end
    mounts[#mounts + 1] = {path = path, proxy = component.proxy(addr)}
    return true
  end
  return false, "Unable to mount"
end

function fs.umount(path)
  checkArg(1, path, "string")
  for k, v in pairs(mounts) do
    if v.path == path then
      mounts[k] = nil
      fs.remove(v.path)
      return true
    elseif v.proxy.address == path then
      mounts[k] = nil
      fs.remove(v.path)
    end
  end
  return false, "No such mount"
end

function fs.mounts()
  local rtn = {}
  for k,v in pairs(mounts) do
    rtn[k] = {path = v.path, address = v.proxy.address, label = v.proxy.getLabel()}
  end
  return rtn
end

-- this saves effort, there's a couple things we still need to do manually though
for k, v in pairs(rootfs) do
  fs[k] = function(path, ...)
    local path, proxy = resolve(path)
    if not proxy then
      return nil, "invalid path"
    end
    return proxy[k](path, ...)
  end
end

-- the functions defined below are there for a reason

local handles = {}

function fs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  local path, proxy = resolve(file)
  if not path or not proxy then
    return nil, "invalid path"
  end
  local h = proxy.open(path, mode)
  if not h then
    return nil, "file not found"
  end
  handles[#handles + 1] = {proxy = proxy, handle = h}
  return #handles
end

function fs.read(h, a)
  checkArg(1, h, "number")
  checkArg(2, a, "number")
  if not handles[h] then
    return nil, "invalid handle"
  end
  return handles[h].proxy.read(handles[h].handle, a)
end

function fs.write(h, d)
  checkArg(1, h, "number")
  checkArg(2, d, "string")
  if not handles[h] then
    return nil, "invalid handle"
  end
  return handles[h].proxy.write(handles[h].handle, d)
end

function fs.close(h)
  checkArg(1, h, "number")
  if not handles[h] then
    return nil, "invalid handle"
  end
  handles[h].proxy.close(handles[h].handle)
  handles[h] = nil
end

function fs.list(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  local files = proxy.list(path)
  local i = 1
  local mt = {
    __call = function()
      i = i + 1
      if files[i - 1] then
        return files[i - 1]
      else
        return nil
      end
    end
  }
  return setmetatable(files, mt)
end

function fs.spaceUsed(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceUsed()
end

function fs.isReadOnly(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.isReadOnly()
end

function fs.spaceTotal(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceTotal()
end

function fs.copy(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local spath, sproxy = resolve(source)
  local dpath, dproxy = resolve(dest)

  local s, err = sproxy.open(spath, "r")
  if not s then
    return false, err
  end
  local d, err = dproxy.open(dpath, "w")
  if not d then
    sproxy.close(s)
    return false, err
  end
  repeat
    local data = sproxy.read(s, 0xFFFF)
    dproxy.write(d, (data or ""))
  until not data
  sproxy.close(s)
  dproxy.close(d)
  return true
end

function fs.rename(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")

  local ok, err = fs.copy(source, dest)
  if ok then
    fs.remove(source)
  else
    return false, err
  end
end

function fs.canonical(path)
  checkArg(1, path, "string")
  local segments = split("/", path)
  for i=1, #segments, 1 do
    if segments[i] == ".." then
      segments[i] = ""
      table.remove(segments, i - 1)
    end
  end
  return cleanPath(table.concat(segments, "/"))
end

function fs.path(path)
  checkArg(1, path, "string")
  local segments = split("/", path)

  return cleanPath(table.concat({table.unpack(segments, 1, #segments - 1)}, "/"))
end

function fs.name(path)
  checkArg(1, path, "string")
  local segments = split("/", path)

  return segments[#segments]
end

function fs.get(path)
  checkArg(1, path, "string")
  if not fs.exists(path) then
    return false, "Path does not exist"
  end
  local path, proxy = resolve(path)

  return proxy
end

function fs.getLabel(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.getLabel()
end

function fs.setLabel(label, path)
  checkArg(1, label, "string")
  checkArg(2, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.setLabel(label)
end

while true do
  local evt, from, operation, arg1, arg2, arg3, arg4 = recv()
  if evt and from and operation then
    if evt == "ipc" then
--      kernel.logger.log("got ipc from", tostring(from))
      if fs[operation] then
--        kernel.logger.log("executing fs." .. operation)
--        kernel.logger.log(tostring(from))
        ipc.send(from, fs[operation](arg1, arg2, arg3, arg4))
--        coroutine.yield()
      else
--        kernel.logger.log("invalid operation", operation)
        ipc.send(from, nil, "invalid operation")
      end
    elseif evt == "component_added" then
      if operation == "filesystem" then
        fs.mount(from)
      end
    elseif evt == "component_removed" then
      if operation == "filesystem" then
        fs.umount(from)
      end
    end
  end
end
