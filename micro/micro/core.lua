-- core --

local addr, invoke = computer.getBootAddress(), component.invoke
_G.kernel = {}
kernel.start = computer.uptime()
kernel.cmdline = {...}
kernel.logger = {}
kernel.logger.log = function()end
kernel.logger.progress = function()end
local gpu = component.list("gpu")()
local screen = component.list("screen")()
local w,h
if gpu and screen then
  invoke(gpu, "bind", screen)
  w, h = invoke(gpu, "maxResolution")
  invoke(gpu, "setResolution", w, h)
  invoke(gpu, "fill", 1, 1, w, h, " ")
  local y = 1
  kernel.logger.log = function(...)
    local msg = table.concat({...}, " ")
    invoke(gpu, "set", 1, y, msg)
    if y == (h - 1) then
      invoke(gpu, "copy", 1, 1, w, h-1, 0, -1)
      invoke(gpu, "fill", 1, h-1, w, 1, " ")
    else
      y = y + 1
    end
  end
  kernel.logger.progress = function(percent)
    invoke(gpu, "set", 1, h, (unicode.char(0x2588)):rep(math.ceil(w / (100 / percent))))
  end
end

kernel.logger.progress(0)
kernel.logger.log("Starting Micro")
kernel.logger.log("Lua version:", _VERSION)

kernel.logger.progress(10)
kernel.logger.log("init base")
function kernel.loadfile(fs, file, env)
  local h = invoke(fs, "open", file)
  if not h then return nil, file .. ": file not found" end
  local data = ""
  repeat
    local c = invoke(fs, "read", h, math.huge)
    data = data .. (c or "")
  until not c
  invoke(fs, "close", h)
  return load(data, "=" .. file, "t", env or _G)
end

kernel.bootfs = component.proxy(computer.getBootAddress())

function kernel.panic(...)
  kernel.logger.log("------------- KERNEL PANIC -------------")
  for line in debug.traceback(table.concat({...}, " ")):gsub("\t", "  "):gmatch("[^\n]+") do
    kernel.logger.log(line)
  end
  kernel.logger.log("----------------------------------------")
  computer.beep(1000, 0.4)
  computer.beep(1000, 0.4)
  while true do
    computer.pullSignal()
  end
end

kernel.logger.progress(20)
kernel.logger.log("init thread")

do
  local thread = {}
  local threads = {}
  local current = 0
  local pid = 1
  local pull = computer.pullSignal
  local uptime = computer.uptime
  local signals = {}

  local function autokill()
    local dead = {}
    for pid, thd in pairs(threads) do
      if thd.dead or (threads[thd.parent] and threads[thd.parent].dead) then
        dead[pid] = true
      end
    end
    for pid, _ in pairs(dead) do
      threads[pid] = nil
    end
  end

  local function gethandler(pid)
    local h, p = threads[pid].handler or gethandler(threads[pid].parent) or kernel.panic
    return h, (p or pid)
  end

  local function handle(err)
    local handler, pid = gethandler(current)
    thread.kill(pid)
    handler(err)
  end

  local function autosleep()
    local sig = {pull(0)}
    if #sig > 0 then
      signals[#signals + 1] = sig
    end
  end

  function thread.spawn(func, name, handler, blacklist)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    checkArg(3, handler, "function", "nil")
    checkArg(4, blacklist, "table", "nil")
    local new = {
      coro = coroutine.create(func),
      name = name,
      handler = handler,
      priority = math.huge,
      ipc = {},
      env = {},
      parent = current,
      blacklist = blacklist or {},
      time = 0,
      dead = false,
      parent = current,
      start = uptime(),
      maxtime = uptime()
    }
    threads[pid + 1] = new
    pid = pid + 1
    return pid
  end

  function thread.kill(pid)
    checkArg(1, pid, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    threads[pid].dead = true
    --coroutine.yield()
  end

  function thread.send(pid, msg, ...)
    checkArg(1, pid, "number")
--    kernel.logger.log("IPC", tostring(current))
    if not threads[pid] then
      return nil, "no such thread"
    end
    local ipc = {current, msg, ...}
--    kernel.logger.log("IPC:", current, "->", pid, "--", tostring(ipc[1]), tostring(ipc[2]))
    threads[pid].ipc[#threads[pid].ipc + 1] = ipc
--    coroutine.yield()
  end

  function thread.current()
    return current
  end

  function thread.find(name)
    checkArg(1, name, "string")
    for pid, proc in pairs(threads) do
      if proc.name == name then
        return pid
      end
    end
    return nil, "thread not found"
  end
  
  function thread.info(proc)
    checkArg(1, proc, "string", "number", "nil")
    if type(proc) == "string" then
      proc = thread.find(proc)
    end
    if not threads[proc] then
      return nil, "no such process"
    end
    return {name = threads[proc].name, parent = threads[proc].parent, uptime = threads[proc].time}
  end

  function thread.start()
    thread.start = nil
    while true do
      local sig = {}
      if #signals > 0 then
        sig = table.remove(signals, 1)
      end

      for pid, proc in pairs(threads) do
        current = pid
        local o, e
--        kernel.logger.log("resuming " .. proc.name)
        if #sig > 0 and not proc.blacklist[sig[1]] then
          o, e = coroutine.resume(proc.coro, table.unpack(sig))
        elseif #proc.ipc > 0 and not proc.blacklist[proc.ipc[1][1]] then
          local ipc = proc.ipc[1]
          table.remove(proc.ipc, 1)
--           kernel.logger.log("IPC:", tostring(ipc[1]), tostring(ipc[2]), ipc[3], "->", tostring(pid))
          o, e = coroutine.resume(proc.coro, "ipc", table.unpack(ipc))
--           kernel.logger.log("RESUMED WITH IPC")
        else
          o, e = coroutine.resume(proc.coro, "resume")
        end
--         kernel.logger.log(proc.name, tostring(o), tostring(e))
        if o == false and e then
--           kernel.logger.log("HANDLING")
          handle(proc.name .. ": " .. e)
        end
      end
--       kernel.logger.log("AUTOKILL")
      autokill()
--       kernel.logger.log("SLEEPING")
      autosleep()
    end
    kernel.panic("init exited")
  end
  kernel.thread = thread
end

kernel.logger.progress(30)
kernel.logger.log("init userspace")

local sandbox = {
  _VERSION = _VERSION,
  _OSVERSION = "Micro",
  assert = assert,
  pcall = pcall,
  xpcall = xpcall,
  ipairs = ipairs,
  getmetatable = getmetatable,
  setmetatable = setmetatable,
  tonumber = tonumber,
  error = error,
  next = next,
  pairs = pairs,
  tostring = tostring,
  type = type,
  rawequal = rawequal,
  rawget = rawget,
  rawset = rawset,
  select = select,
  load = load,
  checkArg = checkArg,
  debug = setmetatable({}, {__index=debug}),
  os = setmetatable({}, {__index=os}),
  bit32 = setmetatable({}, {__index=bit32}),
  math = setmetatable({}, {__index=math}),
  string = setmetatable({}, {__index=string}),
  table = setmetatable({}, {__index=table}),
  unicode = setmetatable({}, {__index=unicode}),
  coroutine = setmetatable({}, {__index=coroutine}),
  component = setmetatable({}, {__index=component}),
  computer = setmetatable({}, {__index=computer}),
  kernel = setmetatable({}, {__index=kernel}),
  ipc = {}
}
sandbox._G = sandbox

kernel.logger.progress(40)
kernel.logger.log("init IPC channels")
function sandbox.ipc.channel(proc)
  checkArg(1, proc, "string")
  local pid, err = kernel.thread.find(proc)
  if not pid then
    return nil, err
  end
  local con = {
    pid = pid
  }
  function con.write(self, msg, ...)
    checkArg(0, self, "table")
    return sandbox.ipc.send(self.pid, msg, ...)
  end
  function con.read(self, timeout)
    checkArg(0, self, "table")
    checkArg(1, timeout, "number", "nil")
    local max = computer.uptime() + (timeout or math.huge)
    repeat
--      kernel.logger.log("reading")
      local evtd = {coroutine.yield()}
      if evtd and #evtd >= 2 then
        local evt, from, msg = evtd[1], evtd[2], {table.unpack(evtd, 3)}
--        kernel.logger.log(evt, tostring(from))
        if evt == "ipc" and from == self.pid then
          return table.unpack(msg)
        end
      end
    until max <= computer.uptime()
    return nil, "timeout exceeded"
  end
  function con.wait(self, msg, ...)
    self:write(msg, ...)
    return self:read()
  end
  function con.close(self)
    checkArg(0, self, "table")
    sandbox.ipc.send(self.pid, "close")
    self = nil
  end
  return con
end

function sandbox.ipc.send(pid, msg, ...)
  checkArg(1, pid, "number")
--  kernel.logger.log("init: IPC", tostring(kernel.thread.current()), "->", tostring(pid))
  local ok, err = kernel.thread.send(pid, msg, ...)
--  kernel.logger.log(tostring(ok), tostring(err))
--  coroutine.yield()
  return ok, err
end

function sandbox.ipc.proxy(proc)
  checkArg(1, proc, "string")
  local con, err = sandbox.ipc.channel(proc)
  if not con then
    return nil, err
  end
  return setmetatable({},{__index=function(tbl,k)
    if k == "close" then
      con:close()
    else
      return function(...)
        return con:wait(k, ...)
      end
    end
  end})
end

kernel.logger.progress(50)
kernel.logger.log("init syscalls")

function sandbox.pspawn(func, name, handler)
  checkArg(1, func, "function")
  checkArg(2, name, "string")
  checkArg(3, handler, "function", "nil")
  return kernel.thread.spawn(func, name, handler, nil, 1)
end

function sandbox.pkill(pid)
  checkArg(1, pid, "number")
  return kernel.thread.kill(pid)
end

function sandbox.eblock(...)
  local args = {...}
  for i=1, #args, 1 do
    checkArg(i, args[i], "string")
    kernel.thread.block(args[i])
  end
end

function sandbox.wait(pid)
  checkArg(1, pid, "number")
  repeat
    local info = kernel.thread.info(pid)
    coroutine.yield()
  until not info
end

function sandbox.exit(code)
  kernel.thread.send(kernel.thread.info(kernel.thread.current()).parent, "exit", (code or 0))
  kernel.thread.kill(kernel.thread.current())
  coroutine.yield()
end

function sandbox.recv()
  local d = {coroutine.yield()}
  if d[1] == "interrupt" then
    error("interrupted")
  else
    return table.unpack(d)
  end
end

sandbox.push = computer.pushSignal

function sandbox.error(err, lvl)
  error(debug.traceback(err), lvl)
end

kernel.logger.progress(60)
kernel.logger.log("load init")
local ok, err = kernel.loadfile(addr, kernel.cmdline.init or "/micro/init.lua", setmetatable({kernel=kernel},{__index=sandbox}))

if not ok then
  kernel.panic(err)
end

kernel.thread.spawn(ok, "init", kernel.panic, {interrupt=true})

kernel.thread.start()

while true do
  computer.pullSignal()
end
