-- OS API --

local oldos = _G.os
local loadfile = ...

_G.os = computer

for i=1, #oldos, 1 do
  table.insert(oldos[i],os)
end

os.run = loadfile -- Might be replaced later, suffices at this point in development.

os.shutdown = function(reboot)
  os.pushSignal("shutdown")
  os.sleep(0.1)
  computer.shutdown(reboot)
end

local last_sleep = os.uptime()
local y = 1
os.status = function(msg) -- Ripped from OpenOS
  if gpu then
    gpu.set(1, y, msg)
    if y == h then
      gpu.copy(1, 2, w, h - 1, 0, -1)
      gpu.fill(1, h, w, 1, " ")
    else
      y = y + 1
    end
  end

  if os.uptime() - last_sleep > 1 then
    local signal = table.pack(os.pullSignal(0))
    -- there might not be any signal
    if signal.n > 0 then
      -- push the signal back in queue for the system to use it
      os.pushSignal(table.unpack(signal, 1, signal.n))
    end
    last_sleep = os.uptime()
  end
end

local hostname = "localhost"

os.hostname = function()
  return hostname
end
