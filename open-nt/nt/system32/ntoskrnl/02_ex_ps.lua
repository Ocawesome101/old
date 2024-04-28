------------------- OpenNT kernel: 02_executive_procstr.lua --------------------
-- Copyright (C) 2020 Ocawesome101                                            --
--                                                                            --
-- This program is free software: you can redistribute it and/or modify       --
-- it under the terms of the GNU General Public License as published by       --
-- the Free Software Foundation, either version 3 of the License, or          --
-- (at your option) any later version.                                        --
--                                                                            --
-- This program is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              --
-- GNU General Public License for more details.                               --
--                                                                            --
-- You should have received a copy of the GNU General Public License          --
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.     --
--------------------------------------------------------------------------------

-- scheduler pretty much copy pasted from Monolith
do
  local thread, threads, sbuf, last, cur = {}, {}, {}, 0, 0
  local pullSignal = computer.pullSignal
  local liveCoro = coroutine.create(function()end)

  local function checkDead(thd)
    local p = threads[thd.parent] or {dead = false, coro = liveCoro}
    if thd.dead or p.dead or coroutine.status(thd.coro) == "dead" or coroutine.status(p.coro) == "dead" then
      p = nil
      return true
    end
    p = nil
  end

  local function getMinTimeout()
    local min = math.huge
    for pid, thd in pairs(threads) do
      if thd.deadline - computer.uptime() < min then
        min = computer.uptime() - thd.deadline
      end
      if min <= 0 then
        min = 0
        break
      end
    end
    return min
  end

  local function cleanup()
    local dead = {}
    for pid, thd in pairs(threads) do
      if checkDead(thd) then
        computer.pushSignal("thread_died", pid)
        nt.ki.log("thread died: " .. pid .. " - " .. thd.name)
        dead[#dead + 1] = pid
      end
    end
    for i=1, #dead, 1 do
      threads[dead[i]] = nil
    end

    local timeout = getMinTimeout()
    local sig = {pullSignal(timeout)}
    if #sig > 0 then
      sbuf[#sbuf + 1] = sig
    end
  end

  local function getHandler(thd)
    local p = threads[thd.parent] or {}
    return thd.handler or p.handler or getHandler(p) or kernel.logger.panic
  end

  local function handleProcessError(thd, err)
    local h = getHandler(thd)
    threads[thd.pid] = nil
    computer.pushSignal("thread_errored", thd.pid, string.format("error in thread '%s' (PID %d): %s", thd.name, thd.pid, err))
    nt.ki.log("thread errored: " .. string.format("error in thread '%s' (PID %d): %s", thd.name, thd.pid, err))
    h(thd.name .. ": " .. err)
  end

  function thread.spawn(func, name, handler, env)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    checkArg(3, handler, "function", "nil")
    checkArg(4, env, "table", "nil")
    last = last + 1
    local current = thread.info() or { data = { io = {[0] = {}, [1] = {}, [2] = {} }, env = {} } }
    env = env or nt.ke.tcopy(current.data.env)
    local new = {
      coro = coroutine.create( -- the thread itself
        func
        --[[function()
          local ok, err = xpcall(func, debug.traceback)
          if not ok and err then error(err) end
        end]]
      ),
      pid = last,                               -- process/thread ID
      parent = cur,                             -- parent thread's PID
      name = name,                              -- thread name
      handler = handler or nt.ki.panic,         -- error handler
      sig = {},                                 -- signal buffer
      ipc = {},                                 -- IPC buffer
      env = env,                                -- environment variables
      deadline = computer.uptime(),             -- signal deadline
      priority = priority,                      -- thread priority
      uptime = 0,                               -- thread uptime
      stopped = false,                          -- is it stopped?
      started = computer.uptime(),              -- time of thread creation
      io      = {                               -- thread I/O streams
        [0] = current.data.io[0],
        [1] = current.data.io[1],
        [2] = current.data.io[2] or current.data.io[1]
      }
    }
    if not new.env.cd then
      new.env.cd = "\\"
    end
    setmetatable(new, {__index = threads[cur] or {}})
    threads[last] = new
    computer.pushSignal("thread_spawned", last)
    return last
  end

  function thread.threads()
    local t = {}
    for pid, _ in pairs(threads) do
      t[#t + 1] = pid
    end
    table.sort(t, function(a,b) return a < b end)
    return t
  end

  function thread.info(pid)
    checkArg(1, pid, "number", "nil")
    pid = pid or cur
    if not threads[pid] then
      return nil, "no such thread"
    end
    local t = threads[pid]
    local inf = {
      name = t.name,
      owner = t.owner,
      priority = t.priority,
      parent = t.parent,
      uptime = t.uptime,
      started = t.started
    }
    if pid == cur then
      inf.data = {
        io = t.io,
        env = t.env
      }
    end
    return inf
  end

  function thread.signal(pid, sig)
    checkArg(1, pid, "number")
    checkArg(2, sig, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    local msg = {
      "signal",
      cur,
      sig
    }
    table.insert(threads[pid].sig, msg)
    return true
  end

  function thread.ipc(pid, ...)
    checkArg(1, pid, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    local ipc = table.pack(
      "ipc",
      cur,
      ...
    )
    table.insert(threads[pid].ipc, ipc)
    return true
  end

  function thread.current()
    return cur
  end

  -- detach from the parent thread
  function thread.detach()
    threads[cur].parent = 1
  end

  -- detach any child thread, parent it to init
  function thread.orphan(pid)
    checkArg(1, pid, "number")
    if not threads[pid] then
      return nil, "no such thread"
    end
    if threads[pid].parent ~= cur then
      return nil, "specified thread is not a child of the current thread"
    end
    threads[pid].parent = 1 -- init
  end

  thread.signals = {
    interrupt = 2,
    quit      = 3,
    stop      = 19,
    continue  = 18,
    term      = 15,
    terminate = 15,
    usr1      = 65,
    usr2      = 66,
    kill      = 9
  }

  function thread.kill(pid, sig)
    return thread.signal(pid, sig or thread.signals.term)
  end

  function thread.start()
    thread.start = nil
    nt.ki.log("START THREAD")
    while #threads > 0 do
      local run = {}
      for pid, thd in pairs(threads) do
        threads[pid].uptime = computer.uptime() - thd.started
        if (thd.deadline <= computer.uptime() or #sbuf > 0 or #thd.ipc > 0 or #thd.sig > 0) and not thd.stopped then
          run[#run + 1] = thd
        end
      end

      local sig = table.remove(sbuf, 1)

      for i, thd in ipairs(run) do
        cur = thd.pid
        local ok, p1, p2
        nt.ki.log("RESUME THREAD " .. thd.pid .. ": " .. thd.name)
        if #thd.ipc > 0 then
          local ipc = table.remove(thd.ipc, 1)
          ok, p1, p2 = coroutine.resume(thd.coro, table.unpack(ipc))
        elseif #thd.sig > 0 then
          local nsig = table.remove(thd.sig, 1)
          if nsig[3] == thread.signals.kill then
            thd.dead = true
            ok, p1, p2 = true, nil, "killed"
          elseif nsig[3] == thread.signals.stop then
            thd.stopped = true
          elseif nsig[3] == thread.signals.continue then
            thd.stopped = false
          else
            ok, p1, p2 = coroutine.resume(thd.coro, table.unpack(nsig))
          end
        elseif sig and #sig > 0 then
          ok, p1, p2 = coroutine.resume(thd.coro, table.unpack(sig))
        else
          ok, p1, p2 = coroutine.resume(thd.coro)
        end
        if (not ok) and p1 then
          handleProcessError(thd, p1)
        elseif ok then
          if p1 and type(p1) == "number" then
            thd.deadline = computer.uptime() + p1
          else
            thd.deadline = math.huge
          end
          thd.uptime = computer.uptime() - thd.started
        end
      end

      if computer.freeMemory() < 1024 then
        local miss = {}
        for i=1, 10, 1 do
          local sig = table.pack(computer.pullSignal(0))
          if sig.n > 0 then
            miss[#miss + 1] = sig
          end
        end
        for i=1, #miss, 1 do
          computer.pushSignal(table.unpack(miss[i]))
        end
      end
      cleanup()
    end
    nt.ki.panic("ALL_THREADS_STOPPED")
  end

  nt.ex.ps = thread
end
