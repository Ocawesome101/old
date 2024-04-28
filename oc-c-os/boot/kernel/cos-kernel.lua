-- C/OS kernel --
-- last known good modules are in /cos/cache/LNG
-- modules are stored in /cos/modules
-- essential modules are always loaded, more may
-- be loaded through startup scripts or
-- sys.loadMod() in the shell

local component = component
local computer = computer
local sys = {} -- we pass a reference to this 
-- table into _G using __index, which allows the
-- kernel to modify it and disallows user programs
-- from doing so
_G.sys = setmetatable({}, {__index = sys})
sys._START = computer.uptime()

-- we do this now, while _G is still writable
function component.get(a, t)
  checkArg(1, a, "string")
  checkArg(2, t, "string", "nil")
  for ca, ct in component.list(t) do
    if ca:sub(1,#a) == a then
      return ca
    end
  end
  return nil, "no such component"
end

-- logger
do
  local gpu, screen = component.get("", "gpu"), component.get("", "screen")
  function sys.log()
  end
  if gpu and screen then
    gpu = component.proxy(gpu)
    sys.gpu = gpu
    gpu.bind(screen)
    local w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.fill(1, 1, w, h, " ")
    local y = 0
    local function put(msg)
      if y == h then
        gpu.copy(1, 1, w, h, 0, -1)
        gpu.fill(1, h, w, 1, " ")
      else
        y = y + 1
      end
      msg = string.format("[%.2f] %s", computer.uptime(), msg)
      gpu.set(1, y, msg)
    end
    function sys.log(...)
      local msg = table.concat(table.pack(...), " ")
      for ln in msg:gmatch("[^\n]+") do
        put(ln)
      end
    end
  end
end

sys.log("vfs")

-- very basic vfs - 'addr:/path/to/file' syntax. this is baked into the kernel.
do
  local function resolve(path)
    local a, p = path:match("^(.-):(.+)")
    a, p = a or computer.getBootAddress(), p or path
    a = component.get(a)
    if (not a) or component.type(a) ~= "filesystem" then
      return nil, "no such filesystem"
    end
    return component.proxy(a), p
  end
  sys.resolve = resolve
end

sys.log("scheduler")

-- scheduler. also in the kernel.
do
  local invoke = component.invoke
  local threads = {}
  local signals = {}
  local pid = 0
  local maxtime = 4 -- protect against TLWOY when we're going through backed up signals
  sys.loop = function()
    sys.loop = nil
    sys.log("sysloop")
    while #threads > 0 do
      local sig = table.remove(signals, 1) or {}
      if #sig > 0 then
        local start = computer.uptime()
        for pid, thd in pairs(threads) do
          local ret = table.pack(coroutine.resume(thd.coro, table.unpack(sig)))
          if (not ret[1]) or coroutine.status(thd.coro) == "dead" then
            sys.log(ret[2])
            threads[pid] = nil
          end
          if computer.uptime() >= start + maxtime then
            goto yield -- this hopefully protects the scheduler from throwing a TLWOY
          end
        end
      end
      ::yield::
      table.insert(signals, table.pack(computer.pullSignal()))
    end
    sys.log("all threads stopped")
    computer.beep("...")
    while true do computer.pullSignal() end
  end

  function sys.spawn(func, name)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    local new = {
      coro = coroutine.create(func),
      name = name
    }
    threads[pid + 1] = new
    pid = pid + 1
    return pid
  end

  function sys.threads()
    local t = {}
    for k,v in pairs(threads) do
      t[k] = v.name
    end
    return t
  end

  function sys.kill(p)
    if threads[p] then
      threads[p] = nil
      return true
    else
      return nil, "thread not found"
    end
  end
end

-- bah, whatever
sys.log("sandbox")
function table.copy(t)
  checkArg(1, t, "table")
  local seen = {}
  local function copy(tbl)
    local ret = {}
    tbl = tbl or {}
    for k, v in pairs(tbl) do
      if type(v) == "table" and not seen[v] then
        seen[v] = true
        ret[k] = copy(v)
      else
        ret[k] = v
      end
    end
    return ret
  end
  return copy(t)
end

local sb = table.copy(_G)
sb._G = sb
sb._ENV = sb
sb.sys = setmetatable({}, {__index = sys, __metatable = {}})
sb.load = function(x,n,m,e) return load(x,n,m,e or sb) end
sys.log("modules")

function loadfile(f, m, e)
  checkArg(1, f, "string")
  checkArg(2, m, "string", "nil")
  checkArg(3, e, "table", "nil")
  local n, p = sys.resolve(f)
  if not n then
    return nil, p
  end
  local h, E = n.open(p, "r")
  if not h then
    return nil, E
  end
  local d = ""
  repeat
    local c = n.read(h, math.huge)
    d = d .. (c or "")
  until not c
  n.close(h)
  return load(d, "="..f, m or "bt", e or sb)
end

local function copy(f1, f2)
  local n1, p1 = sys.resolve(f1)
  local n2, p2 = sys.resolve(f2)
  if not n1 then
    return nil, p1
  elseif not n2 then
    return nil, p2
  end
  local h1, e1 = n1.open(p1, "r")
  if not h1 then
    return nil, e1
  else
    local h2, e2 = n2.open(p2, "w")
    if not h2 then
      n1.close(h1)
      return nil, e2
    else
      local dat = ""
      repeat
        local c = n1.read(h1, math.huge)
        dat = dat .. (c or "")
      until not c
      n1.close(h1)
      n2.write(h2, dat)
      n2.close(h2)
      return true
    end
  end
end

-- module system. almost everything else is
-- outside the kernel.
do
  local essential = {
    "term",
    "repl"
  }
  local limit = 5
  local function try(file)
    local ok, err = loadfile(file, "bt", sb)
    if not ok then
      return nil, err
    end
    local st, ret = pcall(ok)
    if not st and ret then
      return nil, ret
    end
    return ret
  end
  local function tryLoad(m)
    local path = "/cos/modules/"..m..".lua"
    local t = 1
    local ok, err = false
    repeat
      ok, err = try(path)
      t = t + 1
    until t > limit or ok
    if ok then
      sys.log("copying module to /cos/LNG")
      local to = "/cos/LNG/"..m..".lua"
      local ok, err = copy(path, to)
      if not ok then
        sys.log("WARNING: failed copying to /cos/LNG:", err)
      end
    end
    return ok
  end
  local function loadLastKnownGood(m)
    sys.log("falling back to last known good module!")
    local path = "/cos/LNG/"..m..".lua"
    return try(path)
  end
  local mods = {}
  function sys.loadMod(mod)
    checkArg(1, mod, "string")
--    if not mods[mod] then
      sys.log("load module:", mod)
      local ok, err = tryLoad(mod)
      if not ok then
        ok, err = loadLastKnownGood(mod)
      end
      if not ok then
        sys.log("WARNING: module load failed for:", mod)
      end
      mods[mod] = ok and ok
  --  end
    if mods[mod] and mods[mod].load then pcall(mods[mod].load) end
    return (not not ok), err
  end
  function sys.unloadMod(mod)
    if mods[mod] and mods[mod].load and not essential[mod] then
      pcall(mods[mod].unload)
    end
    mods[mod] = nil
    return true
  end

  for k, v in pairs(essential) do
    sys.loadMod(v)
  end
end

computer.pushSignal("init")

sys._FINISH = computer.uptime()
sys.loop()
