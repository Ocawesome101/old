-- A minimal OS, written to be lightweight. --

-- Convenience
local invoke, list, proxy = component.invoke, component.list, component.proxy
-- Get the boot-fs address, and detect other filesystems
local addr = list("filesystem")()
-- Proxy it!
local rootfs = proxy(addr)
-- A table of all connected filesystems
local filesystems = {
  [addr] = proxy(addr)
}
-- Get all filesystems, and initialize proxies for them
for addr in component.list("filesystem") do
  filesystems[addr] = proxy(addr)
end
-- Init GPU and screen stuff
local gpu = list("gpu")()
if not gpu then
  error("GPU required")
end
gpu = proxy(gpu)
local screen = list("screen")()
if not screen then
  error("Screen required")
end
gpu.bind(screen)
gpu.setResolution(gpu.maxResolution())
-- Display management
local x,y = 1,1
local w,h = gpu.getResolution()
local function update()
  computer.pullSignal(0)
end
local function sCursor(nX, nY) -- Set the "cursor" position
  if nX <= w and nY <= h then
    x,y = nX, nY
  end
end
local function sfColor(color) -- Set the foreground color
  gpu.setForeground(color)
end
local function gfColor() -- Get the foreground color
  return gpu.getForeground(color)
end
local function sbColor(color) -- Set the background color
  gpu.setBackground(color)
end
local function gbColor(color) -- Get the background color
  return gpu.getBackground(color)
end
local function rWrite(text) -- A low-level write function
  gpu.set(x,y,text)
  x = x + #text
end
local function scroll() -- Scroll one line
  gpu.copy(1,2,w,h-1,0,-1)
  gpu.fill(1,h,w,1," ")
end
local function clear() -- Clear the screen
  gpu.fill(1,1,w,h," ")
end
local colors = { -- A table of basic colors
  black  = 0x000000,
  red    = 0xFF0000,
  green  = 0x00FF00,
  blue   = 0x0000FF,
  yellow = 0xFFFF00,
  purple = 0xFF00FF,
  aqua   = 0x00FFFF,
  white  = 0xFFFFFF
}
function write(text) -- A better write function
  for char in text:gmatch(".") do
    if char == "\n" then
      if y == h then
        scroll()
        sCursor(1,y)
      else
        sCursor(1,y+1)
      end
    else
      if x == w and y+1 == h then
        scroll()
        sCursor(1, y)
      elseif x == w then
        sCursor(1, y+1)
      end
      rWrite(char)
    end
  end
end
function print(...) -- Print \o/
  local args = {...}
  for i=1, #args, 1 do
    if type(args[i]) == "table" then
      print(table.unpack(args[i]))
    else
      write(tostring(args[i]))
    end
    if i < #args then
      write(" ")
    end
  end
  write("\n")
end
clear()
sCursor(1,1)

print("Lite Kernel 0.1")
print("Initializing signal processing")
local pS = computer.pullSignal
sig = {}
function sig.pull(filter, timeout)
  local data = {}
  repeat
    data = {pS(timeout)}
  until data[1] == filter or filter == nil
  return table.unpack(data)
end
computer.pullSignal = sig.pull
print("Initializing read()")
function read(tHist) -- Nothing fancy, just a read function
  local str = ""
  local hist = {}
  for k,v in pairs(tHist) do
    hist[k] = v
  end
  table.insert(hist, "")
  local hPos = #hist
  local sX, sY = x, y
  local function redraw(c)
    sCursor(sX, sY)
    write((" "):rep(w - sX))
    sCursor(sX, sY)
    write(str .. (c or ""))
  end
  redraw("|")
  while true do
    local e, _, id, altid = sig.pull()
    if e == "key_down" then
      if id == 8 then -- Backspace
        str = str:sub(1,-2)
      elseif id == 13 then -- Enter
        redraw("")
        write("\n")
        return str
      elseif id == 0 then
        if altid == 208 then
          if hPos < #hist then
            hPos = hPos + 1
            str = hist[hPos]
          end
        elseif altid == 200 then
          if hPos > 1 then
            hPos = hPos - 1
            str = hist[hPos]
          end
        end
      else
        if id >= 32 and id <= 126 then
          str = str .. string.char(id)
        end
      end
    end
    redraw("|")
  end
end

function printError(errToPrint)
  local oldColor = gfColor()
  sfColor(colors.red)
  print(errToPrint)
  sfColor(oldColor)
end

local hist = {""}
setmetatable(hist, {__index=table})

local cmds = {
  ["free"] = function()
    print("Used: " .. tostring(math.floor((computer.totalMemory() - computer.freeMemory()) / 1024)) .. "k / " .. tostring(math.floor(computer.totalMemory() / 1024)) .. "k")
  end,
  ["shutdown"] = function()
    computer.shutdown()
  end,
  ["reboot"] = function()
    computer.shutdown(true)
  end,
  ["ls"] = function(dir)
    local files = rootfs.list(dir or "/")
    print(files)
  end,
  ["cat"] = function(file)
    local handle = rootfs.open(file)
    local buffer = ""
    repeat
      local data = rootfs.read(handle, 0xFFFF)
      buffer = buffer .. (data or "")
    until not data
    rootfs.close(handle)
    print(buffer)
  end,
  ["clear"] = function()
    clear()
    sCursor(1,1)
  end,
  ["mkdir"] = function(dir)
    rootfs.makeDirectory(dir)
  end,
  ["rm"] = function(file)
    rootfs.remove(file)
  end
}

local function tokenize(str, sep)
  local rtn = {}
  local word = ""
  for char in str:gmatch(".") do
    if char == sep then
      if word ~= "" then
        table.insert(rtn, word)
        word = ""
      end
    else
      word = word .. char
    end
  end
  if word ~= "" then
    table.insert(rtn, word)
  end
  return rtn
end

while true do
  write("litekernel: ")
  local cmd = read(hist)
  hist:insert(cmd)
  cmd = tokenize(cmd, " ")
  local args = {table.unpack(cmd, 2, cmd.n)}
  cmd = cmd[1]
  for k,v in pairs(cmds) do
    if k == cmd then
      local ret, e = pcall(function()v(table.unpack(args))end)
      if not ret and e then
        printError(e)
      end
    end
  end
end

-- Shut down the computer, if by some chance the while-loop has exited
computer.shutdown()
