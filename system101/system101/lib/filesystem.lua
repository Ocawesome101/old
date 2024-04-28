-- filesystem API --
-- This is different from the OpenOS one --

local status = ...
local component = component -- we need this

-- ex. {["/"] = {node = <rootfs proxy>, path = "/"},
--      ["home"] = {node = <rootfs proxy>, path = "/system101/home"}, ...}
local mounts = {}

local function file_not_found(path)
  return string.format("%s: file not found", path)
end

local filesystem = {}
local function segments(path)
  local segments = {}
  for segm in path:gmatch("[^/\\]+") do
    if segm == ".." then
      segments[#segments] = nil
    elseif segm ~= "." then
      segments[#segments + 1] = segm
    end
  end
  return segments
end

local function resolve(path)
  local split = segments(path)
  local cur = mounts["/"]
  if not mounts["/"] then
    return nil, "root filesystem not mounted"
  end
  -- special case
  if mounts[path] then
    return mounts[path].node, mounts[path].path or "/"
  end
  for i=#split, 1, -1 do
    local segm = split[i]
    local try = table.concat(split, 1, i)
    if mounts[try] then
      local rpath = string.format("%s/%s", mounts[try].path,
                                                table.concat(split, i + 1))
      return mounts[try].node, rpath
    end
  end
  if mounts["/"].node.exists(path) then
    return mounts["/"].node, path
  end
  return nil, file_not_found(path)
end

function filesystem.space(path)
  checkArg(1, path, "string")
  path = path or "/"
  local node, err = resolve(path)
  if not node then
    return nil, err
  end
  return {
    used = node.spaceUsed(),
    total = node.spaceTotal(),
    free = node.spaceTotal - node.spaceUsed()
  }
end

function filesystem.label(lb, path)
  checkArg(1, lb, "string", "nil")
  checkArg(2, path, "string", "nil")
  path = path or "/"
  local node, err = resolve(path)
  if not node then
    return nil, err
  end
  if lb then
    return node.setLabel(lb)
  else
    return node.getLabel()
  end
end

function filesystem.stat(path)
  checkArg(1, path, "string")
  local node, rpath = resolve(path)
  if not node then
    return nil, rpath
  end
  if not node.exists(rpath) then
    return nil, file_not_found(path)
  end
  return {
    type = node.isDirectory(rpath) and "directory" or "file",
    size = node.size(rpath),
    node = node.address,
    writable = not node.isReadOnly()
  }
end

local function fread(self, amt)
  checkArg(1, amt, "number")
  return self.node.read(self.fd, amt)
end

local function fwrite(self, dat)
  checkArg(1, dat, "string")
  return self.node.write(self.fd, dat)
end

local function fseek(self, whence, offset)
  checkArg(1, whence, "string", "nil")
  checkArg(2, offset, "number", "nil")
  return self.node.seek(self.fd, whence, offset)
end

local function fclose(self)
  return self.node.close(self.fd)
end

function filesystem.open(path, mode)
  checkArg(1, path, "string")
  checkArg(2, mode, "string", "nil")
  local node, rpath = resolve(path)
  if not node then
    return nil, rpath
  end
  if not node.exists(rpath) then
    return nil, file_not_found(path)
  end
  if node.isDirectory(rpath) then
    return nil, string.format("%s: is a directory", path)
  end
  local fd = node.open(path, mode or "r")
  return {
    fd = fd,
    node = node,
    read = fread,
    write = fwrite,
    seek = fseek,
    close = fclose
  }
end

function filesystem.remove(file)
  checkArg(1, file, "string")
  local info, err = filesystem.stat(file)
  if not info then
    return nil, err
  end
  if info.type == "directory" then
    return nil, string.format("%s: is a directory", path)
  end
  local node, path = resolve(file)
  if not node then
    return nil, path
  end
  return node.remove(path)
end

function filesystem.list(path)
  checkArg(1, path, "string")
  local node, rpath = resolve(path)
  if not node then
    return nil, rpath
  end
  if not node.isDirectory(rpath) then
    return nil, string.format("%s: not a directory", path)
  end
  local files = node.list(rpath)
  return files
end

function filesystem.mount(prx, path)
  checkArg(1, prx, "table", "string")
  checkArg(2, path, "string")
  if type(prx) == "string" then
    prx = component.proxy(prx)
  end
  path = "/" .. table.concat(segments(path), "/")
  if mounts[path] then
    return nil, "there is already a filesystem mounted there"
  end
  mounts[path] = {node = prx, path = "/"}
  return true
end

function filesystem.umount(path)
  checkArg(1, path, "string")
  mounts["/" .. table.concat(segments(path), "/")] = nil
end

return filesystem
