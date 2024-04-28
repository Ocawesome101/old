-- System calls, all of 'em. --

local sched    = scheduler
local computer = computer

function _G.ipcsend(process, message, ...)
  checkArg(1, process, "string", "number")
  --checkArg(2, message, "string")
  if type(process) == "string" then
    local pid, err = sched.find(process)
    if not pid then
      return nil, err
    end
    process = pid
  end
  local ok, err = sched.ipc(process, message, ...)
  if not ok then
    return nil, err
  end
  local data = {}
  local timeout
  repeat
    data = {coroutine.yield()}
  until data[1] == "ipc" and data[2] == process
  return table.unpack(data, 3)
end

function _G.ipcopen(process)
  checkArg(1, process, "string", "number")
  local pid
  if type(process) == "string" then
    local _pid, err = sched.find(process)
    if not _pid then
      return nil, err
    end
    pid = _pid
  end
  local chan = {
    pid = pid,
    closed = false
  }
  function chan:write(message, ...)
    checkArg(1, message, "string")
    if self.closed then return nil, "cannot operate on closed stream" end
    return ipcsend(self.pid, response, message, ...)
  end
  function chan:close()
    if self.closed then return nil, "cannot operate on closed stream" end
    self.closed = true
    return true
  end
end

function _G.evtpull(timeout)
  checkArg(1, timeout, "number", "nil")
  return coroutine.yield(timeout)
end

function _G.evtpush(signal, ...)
  checkArg(1, signal, "string")
  return computer.pushSignal(signal, ...), coroutine.yield(0)
end

function _G.evtblock(signal)
  checkArg(1, signal, "string")
  return sched.block(signal), coroutine.yield(0)
end

function _G.evtunblock(signal)
  checkArg(1, signal, "string")
  return sched.unblock(signal), coroutine.yield(0)
end

function _G.detach()
  return sched.detach(), coroutine.yield(0)
end

function _G.spawn(func, name, handler, blacklist, env, stdin, stdout)
  checkArg(1, func, "function")
  checkArg(2, name, "string")
  return sched.spawn(func, name, handler, blacklist, env, (require and require("users").current()) or nil, stdin, stdout), coroutine.yield()
end

function _G.spawnfile(file, name, handler, blacklist, env, stdin, stdout)
  checkArg(1, file, "string")
  checkArg(2, name, "string", "nil")
  local name = name or file
  local response = {}
  local ok, err = ipcsend("drv/filesystem", "open", file)
  if not ok then
    return nil, err
  end
  if not response[1] then
    return nil, response[2]
  end
  local data = response[1]:readAll()
  response[1]:close()
  local ok, err = load(data, "=" .. file, "bt", _G)
  if not ok then
    return nil, err
  end
  return spawn(ok, name, handler, blacklist, env, (require and require("users").current()) or nil, stdin, stdout)
end

function _G.current()
  return sched.current(), coroutine.yield(0)
end

function _G.kill(pid)
  checkArg(1, pid, "number")
  return sched.kill(pid)
end

function _G.die()
  kill(current())
end
