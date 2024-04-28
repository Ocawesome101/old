-- L4-inspired microkernel --

_G._OSVERSION = "OC-L4 v0.1"

local list, proxy, invoke = component.list, component.proxy, component.invoke

local bootfs = proxy(computer.getBootAddress())

local k = {}
k.log = function()end
k.progress = function()end
k.pull = computer.pullSignal
k.panic = function(r)
  k.log("==== crash " .. os.date() .. " ====")
--  k.log_cr()
  local trace = debug.traceback(r):gsub("\t","  ")
  for line in trace:gmatch("[^\n]+") do
    k.log(line)
    --k.log_cr()
  end
  while true do k.pull() end
end

do
  local gpu, screen = list("gpu")(), list("screen")()
  if gpu and screen then
    gpu = proxy(gpu)
    gpu.bind(screen)
    local w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.fill(1, 1, w, h, " ")
    local y = 1
    local function cr()
      if y == h - 1 then
        gpu.copy(1, 1, w, h - 1, 0, -1)
        gpu.fill(1, h - 1, w, 1, " ")
      else
        y = y + 1
      end
    end
    function k.log(...)
      local m = table.concat({"[" .. os.date() .. "]", ...}, " ")
      gpu.set(1, y, m)
      cr()
    end
    function k.progress(pct)
      gpu.set(1, h, ("X"):rep((math.ceil(w / (100 / pct)))))
    end
  end
end

k.log(_OSVERSION, "starting on", _VERSION)

k.log("Setting up...")

k.progress(10)

local scheduler = {}
do
  local threads = {}
  local cur     = 0
  local last    = 0
  local signals = {}

  local function cleanup()
    local dead = {}
    for pid, thread in pairs(threads) do
      proxy(list("sandbox")()).log(pid, thread.name, thread.parent, thread.coro)
      if thread.dead or (thread.coro and coroutine.status(thread.coro) == "dead") --[[or (threads[thread.parent] and (threads[thread.parent].dead or (threads[thread.parent].coro and coroutine.status(threads[thread.parent].coro == "dead"))))]] then
        dead[#dead + 1] = pid
      end
    end
    for i=1, #dead, 1 do
      threads[dead[i]] = nil
    end

    local timeout = math.huge
    for pid, thread in pairs(threads) do
      if thread.deadline - computer.uptime() < timeout then
        timeout = thread.deadline - computer.uptime()
      end
      if timeout <= 0 then
        timeout = 0
        break
      end
    end

    local sig = {k.pull(timeout)}
    if #sig > 0 then
      signals[#signals + 1] = sig
    end
  end

  local function getHandlerFn(pid)
    return threads[pid].handler or getHandlerFn(threads[pid].parent) or error
  end

  local function handleError(err, pid)
    local handler, toKill = getHandlerFn(pid)
    handler(err)
    scheduler.kill(toKill or pid)
  end

  local GLOBAL_ENV = {}

  function scheduler.spawn(func, name, handler, blacklist, env, owner, stdin, stdout)
    checkArg(1, func,      "function")
    checkArg(2, name,      "string")
    checkArg(3, handler,   "function", "nil")
    checkArg(4, blacklist, "table",    "nil")
    checkArg(5, env,       "table",    "nil")
    checkArg(6, owner,     "string",   "nil")
    checkArg(7, stdin,     "table",    "nil")
    checkArg(8, stdout,    "table",    "nil")
    env = setmetatable(env or {}, { __index = GLOBAL_ENV })
    local new = {
      coro      = coroutine.create(func),
      name      = name,
      handler   = handler,
      blacklist = blacklist or {},
      ipc       = {},
      env       = env,
      uptime    = 0,
      owner     = owner or "root",
      parent    = cur,
      start     = computer.uptime(),
      deadline  = computer.uptime()
    }
    last = last + 1
    threads[last] = new
    return last
  end

  function scheduler.kill(pid)
    checkArg(1, pid, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    threads[pid].dead = true
  end

  function scheduler.current()
    return cur
  end

  function scheduler.threads()
    local thr = {}
    for pid, thread in pairs(threads) do
      thr[#thr + 1] = {
        pid    = pid,
        name   = thread.name,
        uptime = thread.uptime,
        owner  = thread.owner,
        start  = thread.start,
        parent = thread.parent
      }
    end
    return thr
  end

  function scheduler.info(pid)
    checkArg(1, pid, "number", "nil")
    pid = pid or cur
    if not threads[pid] then
      return nil, "no such thread"
    end
    local t = threads[pid]
    return {
      name   = t.name,
      uptime = t.uptime,
      owner  = t.owner,
      start  = t.start,
      parent = t.parent
    }
  end

  function scheduler.find(name)
    checkArg(1, name, "string")
    for pid, thread in pairs(threads) do
      if thread.name == name then
        return pid
      end
    end
    return nil, "thread not found"
  end

  function scheduler.ipc(pid, message, ...)
    checkArg(1, pid, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    table.insert(threads[pid].ipc, {"ipc", cur, message, ...})
    return true
  end

  function scheduler.start()
    scheduler.start = nil
    k.log("Starting scheduler")

    while true do
      local toRun = {}
      for pid, thread in pairs(threads) do
        if thread.deadline <= computer.uptime() or #signals > 0 or #thread.ipc > 0 then
          toRun[pid] = thread
        end
      end

      local sig = {}
      if #signals > 0 then
        sig = table.remove(signals, 1)
      end

      for pid, thread in pairs(toRun) do
        local ret
        cur = pid
        if #thread.ipc > 0 then
          local ipc = table.remove(thread.ipc, 1)
          ret = {coroutine.resume(thread.coro, table.unpack(ipc))}
        elseif #sig > 0 and not thread.blacklist[sig[1]] then
          ret = {coroutine.resume(thread.coro, table.unpack(sig))}
        else
          ret = {coroutine.resume(thread.coro)}
        end

        if ret[2] then
          if not ret[1] then
            handleError(ret[2], cur)
          elseif type(ret[2]) == "number" then
            thread.deadline = computer.uptime() + ret[2]
          end
        else
          thread.deadline = math.huge
        end
      end

      cleanup()
    end

    k.panic("All threads died")
  end
end

k.progress(20)

k.log("Create userspace sandbox")
local userspace = {
  _VERSION      = _VERSION,
  _OSVERSION    = _OSVERSION,
  assert        = assert,
  pcall         = pcall,
  xpcall        = xpcall,
  pairs         = pairs,
  ipairs        = ipairs,
  setmetatable  = setmetatable,
  getmetatable  = getmetatable,
  tostring      = tostring,
  tonumber      = tonumber,
  type          = type,
  error         = error,
  select        = select,
  next          = next,
  rawequal      = rawequal,
  rawget        = rawget,
  rawset        = rawset,
  load          = load,
  checkArg      = checkArg,
  debug         = setmetatable({}, {__index = debug}),
  os            = setmetatable({}, {__index = os}),
  bit32         = setmetatable({}, {__index = bit32}),
  math          = setmetatable({}, {__index = math}),
  string        = setmetatable({}, {__index = string}),
  table         = setmetatable({}, {__index = table}),
  unicode       = setmetatable({}, {__index = unicode}),
  coroutine     = setmetatable({}, {__index = coroutine}),
  component     = setmetatable({}, {__index = component}),
  computer      = setmetatable({}, {__index = computer}),
  kernel        = k,
  scheduler     = scheduler
}

userspace._G = userspace

k.progress(30)
userspace.loadfile = function(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  mode = mode or "bt"
  env = env or userspace
  local handle, err = bootfs.open(file, "r")
  if not handle then
    return nil, file .. ": file not found"
  end
  local data = ""
  repeat
    local tmp = bootfs.read(handle, math.huge)
    data = data .. (tmp or "")
  until not tmp
  bootfs.close(handle)
  return load(data, "=" .. file, mode, env)
end

k.log("Loading init")
k.progress(40)

local ok, err = userspace.loadfile("/l4/init.lua")
if not ok then
  k.panic(err)
end

scheduler.spawn(ok, "/l4/init.lua", k.panic, { interrupt = true })

scheduler.start()

k.panic("Unexpected boot process halt")

while true do
  k.pull()
end
