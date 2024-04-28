-- minix - implementation of the 6 essential *NIX syscalls --
-- open(), read(), write(), close(), fork(), and exec() are all that userspace has
-- besides standard Lua functions (minus io, minus package?).

-- very basic vfs - we can't do *everything* with a devfs, gotta set up required
-- things first
local mnt = {["/"] = component.proxy(computer.getBootAddress())}

local function split(p)
  local ss = {}
  for s in p:gmatch("[^/]+") do
    if s == ".." then
      if #ss > 0 then table.remove(ss, #ss) end
    else
      ss[#ss+1] = s
    end
  end
  return ss
end

local function resolve(path)
  local segs = split(path)
  if path == "/" then
    return mnt["/"]
  end
  for i=#segs, 1, -1 do
    local try = "/"..table.concat(segs, "/", 1, i)
    local ret = "/"..table.concat(segs, "/", i + 1)
    if mnt[try] then
      return mnt[try], ret
    end
  end
  return nil
end

-- open, read, write, close
do
  local fds = {}

  local n = 0
  function open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    local node, path = resolve(file)
    if not node then
      return nil, "file not found"
    end
    local fd = node.open(path, mode)
    fds[n+1] = {node=node, fd=fd}
    n=n+1
    return n
  end

  function read(fd, amt)
    checkArg(1, fd, "number")
    checkArg(2, amt, "number")
    local f = fds[fd]
    if not f then
      return nil, "bad file descriptor"
    end
    return f.node.read(f.fd, amt)
  end

  function write(fd, dat)
    checkArg(1, fd, "number")
    checkArg(2, dat, "string")
    local f = fds[fd]
    if not f then
      return nil, "bad file descriptor"
    end
    return f.node.write(f.fd, dat)
  end

  function close(fd)
    checkArg(1, fd, "number")
    local f = fds[fd]
    if not f then
      return nil, "bad file descriptor"
    end
    fds[fd] = nil
    return f.node.close(f.fd)
  end
end

-- TODO: boot log?

local function readfile(f)
  local fd, err = open(f, "r")
  if not fd then
    return nil, err
  end
  local dat = ""
  repeat
    local ch = read(fd, math.huge)
    data = data .. (ch or "")
  until not ch
  close(fd)
  return dat
end

-- devfs
do
  local adps = "/lib/adapters/"
  local function loadadp(a)
    local p = string.format("%s/%s.lua", adps, a)
    local d, e = readfile(p)
    if not d then
      return nil, e
    end
    local ok, er = load(d, "="..p, "bt", _G)
    if not ok then
      return nil, er
    end
    return ok()
  end

  local ftr = {
    ["/"] = {
      isdir = true,
      child = {
        ["zero"] = {
          isdir = false,
          read = function(self, fd, amt)
            if amt > 2048 then amt = 2048 end
            return string.rep("\0", amt)
          end
        },
        ["null"] = {
          isdir = false,
          read = function() return nil end,
          write = function() end
        },
        ["flist"] = {
          isdir = false,
          fds = {},
          read = function(self, fd)
            if self.fds[fd] then
              return self.fds[fd]()
            else
              return nil
            end
          end,
          write = function(self, fd, dat)
            if self.fds[fd] then
              return nil -- cannot list one entry before previous has cleared
            end
            local n,p = resolve(dat)
            if not n then
              return nil
            end
            local files = n.list(p)
            local iter = function()
              local k,v = next(files)
              files[k or false] = nil
              if #files == 0 then
                self.fds[fd] = nil
              end
              return v
            end
            self.fds[fd] = iter
            return true
          end,
          close = function(self, fd)
            self.fds[fd] = nil
          end
        }
      }
    }
  }
  local fsc = {}
end
