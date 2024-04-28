-- Standard IO: print(), error(), and io.error() --

_G.io = {}

local panic = error
local cy = 5
local cx = 1

os.status("Getting screen width/height")
local w,h = gpu.getResolution()

io.getlines = function(str)
  local lines = {}
  for i=1, string.len(str)/w, w do
    table.insert(lines,str:sub(i,(i+w or len)))
  end
  return lines
end

local last_sleep = os.uptime()

__screen.update = function()return nil end

_G.write = function(str) -- Very similar to os.status()
  if gpu then
    gpu.set(cx, cy, str)
    __screen.update()
    if y == h then
      gpu.copy(1, 2, w, h - 1, 0, -1)
      gpu.fill(1, h, w, 1, " ")
    else
      cy = cy + 1
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

_G.print = function(str)
  write(str)
  cx = 1
end

io.clearLine = function()
  local t = ""
  for i=1, h, 1 do
    t = t .. " "
  end

  write(t)
end

print("Initialized io library")
