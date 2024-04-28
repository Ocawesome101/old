-- An attempt to make something Open-Kernel compatible --

-- More functions in the computer lib. Mostly stubs for compatibility.
function computer.freeMemory()
  return 1024^2
end

function computer.totalMemory()
  return (1024^2)*2
end

function computer.uptime()
  return os.epoch("utc")
end

-- Filesystem API compatibility
fs.makeDirectory = fs.makeDir
fs.remove = fs.delete
fs.isDirectory = fs.isDir
fs.getLabel = function() return "Open Kernel" end

-- An emulated component library. Probably very buggy. Definitely not fully compatible.
_G.component = {}

local emu_components = {
  computer = {
    type = function()return "computer" end,
    address = function()return "0ad-345234-623-42234-5432342" end -- NOT a valid address.
  },
  gpu = {
    type = function()return "gpu" end,
    address = function()return "2ab-235243-765-28373-1673424" end
  },
  filesystem = {
    type = function()return "filesystem" end,
    address = function()return "3ab-72354-613-44737-2247a463" end
  }
}

function component.list(type)
  return loadstring( "return " .. (type or "filesystem") )
end

function component.proxy(type)
  if emu_components[type] then
    return emu_components[type]
  else
    return {
      address = function() return type end,
      type = function() return table.concat({tostring(math.random(111,999)),tostring(math.random(11111,99999)),tostring(math.random(111,999)),tostring(math.random(11111,99999)),tostring(math.random(11111111,99999999))},"-") end
    }
  end
end

function component.invoke(type, func, ...)
  if type == "filesystem" then
    return fs[func](...)
  end
end

-- Bodge in anti-crash when using colors
local oldSetColor = term.setTextColor
function term.setTextColor(color)
  if color == 0x000000 then
    oldSetColor(32768)
  else
    oldSetColor(1)
  end
end

-- Copy-pasted from Open Kernel.

local KERNEL_VERSION = "Open Kernel 0.1.0-cc"

function write(str)
  local str = str or ""
  local x, y = term.getCursorPos()
  local w, h = term.getSize()

  local function newline()
    if y == h then
      term.scroll()
      term.setCursorPos(1,y)
    else
      term.setCursorPos(1,y+1)
    end
  end

  for c in str:gmatch(".") do
    x, y = term.getCursorPos()
    if c == "\n" then
      newline()
    else
      if x == w+1 then
        newline()
      elseif y == h then
        term.scroll(1)
        term.setCursorPos(1,y-1)
      end
      term.write(c)
    end
  end
end

function print(...)
  local toPrint = {...} or {""}
  for i=1, #toPrint, 1 do
    write(tostring(toPrint[i]))
    if i < #toPrint then
      write(" ")
    end
  end
  write("\n")
end

local function time() -- Properly format the computer's uptime for printing
  local r = tostring(computer.uptime())
  local c,_ = r:find("%.")
  local c = c or 4
  if #r > 7 then -- Truncate to 7 characters
    r = r:sub(1,7)
  end
  if c < 4 then
    r = string.rep("0",4-c) .. r
  elseif c > 4 then
    r = r .. string.rep("0",c-4)
  end
  while #r < 7 do
    r = r .. "0"
  end
  return r
end

local function status(msg)
  print("[ " .. time() .. " ] " .. msg)
end

local reasons = {
  "Kernel panicking? I INVENTED kernel panicking!",
  "Run away! RUN AWAAAAAAY!",
  "No reason was given. Strange.",
  "Too many secrets",
  "This kernel was made by Ocawesome101"
}

local function panic(reason)
  local reason = reason or reasons[math.random(1,5)]
  local w,h = term.getSize()
  print(("="):rep(w))
  status("KERNEL PANIC: " .. reason)
  status("Press S to shut down your computer.")
  print(("="):rep(w))
  while true do
    local e, _, id = computer.pullSignal()
    if e == "key_down" and string.char(id) == "s" then
      computer.shutdown(false)
    end
  end
end

_G.kernel = {}
kernel.log = status
function kernel.version() return KERNEL_VERSION end
kernel.shutdown = computer.shutdown

-- Necessary. unfortunately.

local function unpack(t, i)
  local i = i or 1
  if i <= #t then
    return t[i], unpack(t, i + 1)
  end
end

function table.unpack(tbl)
  return unpack(tbl)
end

term.setCursorBlink(false)

function term.update()
  return true
end

local ok, err = loadfile("/sbin/init.lua")
if not ok then
  error(err)
end
ok(panic)
