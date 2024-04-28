-- partial io lib, will load more when needed --

_G.io = {}

local drv_term = ipc.channel("drv_term")
local drv_fs = ipc.channel("drv_filesystem")

local stdio = {
  read = function()
    return drv_term:wait("read")
  end,
  write = function(str)
    checkArg(1, str, "string")
    return drv_term:wait("write", str)
  end,
  close = function()
    error("cannot close default stdio")
  end
}

local function open(file, mode)
  return drv_fs:wait("open", file, mode)
end

local function create(handle, mode, isTTY)
  local mode = mode or "r"
  local handle = {
--[[    rbuf = "", -- buffering will be implemented at some point
    wbuf = "",
    bufsize = 512,]]
    tty = isTTY or false,
    stream = handle
  }
  function handle.__read(self, amount)
    if self.tty then
      return self.stream.read()
    else
      return drv_fs:wait("read", self.stream, amount)
    end
  end
  function handle.read(self, amount)
    checkArg(1, amount, "string", "number", "nil")
    if self.closed then return nil, "cannot operate on closed stream" end
    amount = (type(amount) == "string" and amount:sub(1, 2)) or "l"
    if type(amount) == "number" then
      return self:__read(amount)
    elseif amount == "a" or amount == "*a" then
      local d = ""
      repeat
        local c = self:__read(math.huge)
        d = d .. (c or "")
      until not c
      return d
    elseif amount == "L" or amount == "*L" then
      local l = ""
      repeat
        local c = self:__read(1)
        l = l .. (c or "")
        local x
        if c == "\n" or not c then
          x = true
        end
      until x
      return l
    elseif amount == "l" or amount == "*l" then
      local l = self:read("L")
      if l:sub(-1) == "\n" then l = l:sub(1, -2) end
      return l
    else
      return nil, "unsupported amount " .. amount
    end
  end
  function handle.write(self, data)
    checkArg(1, data, "string")
    if self.closed then return nil, "cannot operate on closed stream" end
    if self.tty then
      return self.stream.write(data)
    else
      return drv_fs:wait("write", self.stream, data)
    end
  end
  function handle.close(self)
    if self.closed then return nil, "cannot operate on closed stream" end
    if not self.tty then
      drv_fs:wait("close", self.stream)
    else
      self.stream.close()
    end
    self.closed = true
  end
  return handle
end

io.stdin = create(stdio, "r", true)
io.stdout = create(stdio, "w", true)
io.stderr = create(stdio, "w", true)

function io.output()
  return io.stdout
end

function io.input()
  return io.stdin
end

function io.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  if file == "-" then
    return create(stdio, mode)
  end
  
  local handle = open(file, mode)
  return create(handle, mode)
end

function io.write(...)
  local args = {...}
  local towrite = ""
  for i=1, #args, 1 do
    towrite = towrite .. tostring(args[i])
  end
  io.output():write(towrite)
end

function io.read(amount)
  return io.input():read(amount)
end

setmetatable(io, {__index=function()
  setmetatable(io, {})
  dofile("/micro/lib/io_full.lua")
end})

function print(...)
  return io.write(..., "\n")
end
