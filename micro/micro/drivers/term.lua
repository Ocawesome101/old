-- term --

local gpu = ipc.proxy("drv_gpu")

local term = {}
local x, y = 1, 1
local w, h = gpu.getResolution()
local blink = true
local shown = true

local function cursor()
  w,h = gpu.getResolution()
  if shown then
    blink = not blink
    local char = gpu.get(x, y)
    local fg = gpu.getForeground()
    local bg = gpu.getBackground()
    if blink then
      gpu.setForeground(bg)
      gpu.setBackground(fg)
    end
    gpu.set(x, y, char)
    if blink then
      gpu.setForeground(fg)
      gpu.setBackground(bg)
    end
  end
end

function term.setCursor(nx, ny)
  checkArg(1, nx, "number")
  checkArg(2, ny, "number")
  if nx <= w and ny <= h then
    local old = shown
    shown = false
    blink = false
    cursor()
    shown = old
    cursor()
    x, y = nx, ny
  end
end

function term.getCursor()
  return x, y
end

function term.scroll(lines)
  checkArg(1, lines, "number")
  gpu.copy(1, 1, w, h, 0, -1)
  gpu.fill(1, h, w, 1, " ")
end

function term.write(str)
  checkArg(1, str, "string")
--  kernel.logger.log("WRITE")
  for line in str:gmatch(("."):rep(w - x)) do
    for l in line:gmatch("[^\n]+") do
      gpu.set(x, y, l)
      term.setCursor(x + #l, y)
      if y == h then
        term.scroll(1)
      else
        y = y + 1
      end
      x = 1
    end
  end
end

function term.clear()
  kernel.logger.log("CLEAR")
  gpu.fill(1, 1, w, h, " ")
  term.setCursor(1, 1)
end

function term.read(hist, replace)
  checkArg(1, hist, "table", "nil")
  checkArg(2, replace, "string", "nil")
  local buffer = ""
  local pos = 1
  local startx, starty = term.getCursor()
  local posX, posY
  local function redraw()
    term.setCursor(startx, starty)
    term.write(buffer:sub(0, pos))
    posX, posY = term.getCursor()
    term.write(buffer:sub(pos + 1) .. " ")
    term.setCursor(posX, posY)
  end
  while true do
    redraw()
    local sig, _, name, code = recv()
    if sig == "key_down" then
      if name >= 32 and name <= 126 then
        buffer = buffer:sub(0, pos) .. string.char(name) .. buffer:sub(pos + 1)
        pos = pos + 1
      elseif name == 8 then -- backspace
        if pos >= 1 then
          buffer = buffer:sub(1, pos - 1) .. buffer:sub(pos + 1)
          pos = pos - 1
        end
      elseif name == 13 then -- enter/return
        term.write("\n")
        break
      elseif code == 203 then -- left arrow
        if pos >= 1 then
          pos = pos - 1
        end
      elseif code == 205 then -- right arrow
        if pos <= #buffer then
          pos = pos + 1
        end
      end
    end
  end
  return buffer
end

local time = computer.uptime()
while true do
  local evt, from, operation, arg1, arg2, arg3, arg4 = recv()
  --[[if evt ~= "resume" then
    kernel.logger.log(evt, from, operation, arg1, arg2, arg3, arg4)
  end]]
  if evt == "ipc" then
--    kernel.logger.log("TERM", operation, "<-", from, "=", kernel.thread.info(from).name)
    if term[operation] then
      ipc.send(from, term[operation](arg1, arg2, arg3, arg4))
    else
      ipc.send(from, "invalid operation")
    end
  end
  if time <= computer.uptime() then
    time = computer.uptime() + 0.5
    cursor()
  end
end
