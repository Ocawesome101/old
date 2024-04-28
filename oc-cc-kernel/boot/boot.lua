-- Works with CC-BIOS! --

term.clear()
term.setCursorPos(1,1)

local bootDir = "/boot/oc-cc-kernel"
local topmsg = "Setting up sandbox..."

local function pad(num, len)
  local rtn = tostring(num)
  while #rtn < len do
    rtn = "0" .. rtn
  end

  return rtn
end

local starttime = os.epoch("utc")

local function gettime()
  return os.epoch("utc") - starttime
end

local function log(msg)
  local time = pad(gettime(), 6)
  time = time:sub(1,#time-3) .. "." .. time:sub(#time-2,#time)
  print("{" .. time .. "} " .. msg)

  local ox, oy = term.getCursorPos()
  term.setCursorPos(1,1)
  term.clearLine()
  print(topmsg)
  term.setCursorPos(ox, oy)
  sleep(0.05)
end

term.setCursorPos(1,2)

local function tcopy(tbl)
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end


  return rtn
end

local function fcopy(func)
  local r = function(...)
    func(...)
  end

  return r
end

log("figure out what we're running on")
local hwtype
if ccemux then
  hwtype = "CCEmuX"
elseif config and periphemu then
  hwtype = string.gsub(os.about(), "\n.+$", "")
else
  hwtype = "ComputerCraft"
end

local hwid
if term.isColor() then
  hwid = hwtype .. " ccLua51-Advanced"
else
  hwid = hwtype .. " ccLua51-Standard"
end

log("running on " .. hwid)

log("Check what BIOS we're using")

local ccBIOS = false

if os.version():sub(1,7) == "CC-BIOS" then
  ccBIOS = true
end

local osenv = {}
if not ccBIOS then
  log("init osenv")
  
  log("add os API")
  osenv.os = tcopy(os)
  
  osenv.read = read
  
  log("tweak")
  osenv.os.version = function()
    return nil
  end
  
  log("add fs API")
  osenv.fs = tcopy(fs)
  
  if ccemux then
    log("add CCEmuX interface")
    osenv.ccemux = ccemux
  end
  
  log("add load, loadstring, loadfile")
  osenv.load = load
  osenv.loadstring = loadstring
  osenv.loadfile = loadfile
  
  log("setfenv, getfenv, pairs")
  osenv.setfenv = setfenv
  osenv.getfenv = function(arg)
    local tge = getfenv(arg)
    return tge
  end
  
  osenv.pairs = pairs
  
  log("pcall, xpcall")
  osenv.pcall = pcall
  osenv.xpcall = xpcall
  
  log("select")
  osenv.select = select
  log("next")
  osenv.next = next
  
  log("type")
  osenv.type = type
  
  log("add string, table APIs")
  osenv.string, osenv.table = string, table
  
  log("tostring, tonumber")
  osenv.tostring, osenv.tonumber = tostring, tonumber
  
  log("add math API")
  osenv.math = math
  
  log("write, clearLine")
  osenv.write = write
  osenv.clearLine = function()
    term.clearLine()
  end
  
  log("setTextColor, getTextColor")
  osenv.setTextColor = function(color)
    term.setTextColor(color)
  end
  
  osenv.getTextColor = function(color)
    return term.getTextColor()
  end
  
  log("setBackgroundColor, getBackgroundColor")
  osenv.setBackgroundColor = function(color)
    term.setBackgroundColor(color)
  end
  
  osenv.getBackgroundColor = function()
    return term.getBackgroundColor()
  end
  
  log("setPaletteColor, getPaletteColor")
  osenv.setPaletteColor = function(color, ...)
    term.setPaletteColor(color, ...)
  end
  
  osenv.getPaletteColor = function(color)
    return term.getPaletteColor(color)
  end
  
  log("setCursorPos, getCursorPos")
  osenv.setCursorPos = function(x,y)
    term.setCursorPos(x,y)
  end
  
  osenv.getCursorPos = function()
    return term.getCursorPos()
  end
  
  log("clear, getSize")
  osenv.clear = function()
    term.clear()
  end
  
  osenv.getSize = function()
    return term.getSize()
  end
  
  log("add colors API")
  osenv.colors = tcopy(colors)
  
  osenv.error = error
  
  log("finalize osenv")
  osenv._G = osenv
  osenv._ENV = osenv
else
  for k,v in pairs(term) do -- The hacky way out, lol
    if k ~= "write" then
      _G[k] = v
    end
  end
end

topmsg = "Loading kernel..."

log("check for kernel")
if not fs.exists(bootDir .. "/kernel.lua") then
  log("kernel not present, cannot continue")
  error("kernel not found")
end

log("found kernel")
log("fetching kernel flags from " .. bootDir .. "/kflags.cfg")

local kflags = ""
local handle = fs.open(bootDir .. "/kflags.cfg", "r")
if not handle then
  log("warn: kernel flags not found. Launching with flags='fullcolor=" .. tostring(term.isColor()) .. "'")
  kflags = "fullcolor=" .. tostring(term.isColor())
else
  kflags = handle.readLine() .. "fullcolor=" .. tostring(term.isColor())
  handle.close()
end

log("loading kernel")

local kernel, err = loadfile(bootDir .. "/kernel.lua")

if not kernel then
  log("error " .. err .. " while loading kernel.lua")
  error("Failed to load kernel")
end

if not ccBIOS then
  log("executing sandboxed kernel with flags " .. kflags)

  setfenv(kernel, osenv)
end

kernel(kflags, hwid, starttime, ccBIOS)
