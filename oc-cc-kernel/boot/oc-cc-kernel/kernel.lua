-- oc-cc-kernel. A *NIX-inspired mostly-monolithic kernel --

local flags = {...}

local hwid = flags[2]
local starttime = flags[3]
local ccBIOS = flags[4]
flags = flags[1]

os.ccbios = function()
  return ccBIOS
end

local function space(...)
  local a = {...}
  local r = ""
  for i=1, #a, 1 do r = r .. a[i] .. " " end
  return r
end

local kernelVersion = "0.7.2"
local kernelArch    = "ccLua51"
local kernelType    = "cc-Unix"
local kernelName    = "oc-cc-kernel"
local kernelUname   = space(kernelName, kernelVersion, kernelArch, kernelType)

write("[[ INIT KERNEL ]]\n")

if ccBIOS then
  os.loadAPI("/rom/apis/colors.lua")
else
  function print(...)
    local p = {...}
    for i=1, #p, 1 do
      write(tostring(p[i]) .. " ")
    end
    write("\n")
  end

  sleep = os.sleep
end

local kernelinittime = starttime

local status = "initialize kernel"

local function setStatus(stat)
  status = stat
end

local function pad(num)
  local rtn = tostring(num)
  while #rtn < 6 do rtn = "0" .. rtn end
  rtn = rtn:sub(1, #rtn-3) .. "." .. rtn:sub(#rtn-2, #rtn)
  return rtn
end

local function time()
  return pad(os.epoch("utc") - kernelinittime)
end

local function log(msg)
  print("[" .. time() .. "] " .. msg)

  local ox, oy = getCursorPos()
  setCursorPos(1,1)
  clearLine()
  print(status)
  setCursorPos(ox, oy)
  sleep(0.05)
end

local function kernel_panic(reason, _)
  reason = reason or "RUN AWAY! RUN AWAAAAAAY!"
  print("")
  log("======================")
  log("Kernel panic!")
  log("Panic reason: " .. reason)
  log("======================")
  log("Press R to restart.")

  while true do
    local e, id = os.pullEventRaw()
    if id == "r" then
      _()
    end
  end
end

log("Welcome to " .. kernelUname)
log("Seting up sysinfo API")
local hostname = "localhost"
sysinfo = {}
sysinfo.cpuArch = function()return kernelArch end
sysinfo.hwid = function()return hwid end

sys = {}
sys.hostname = function()return hostname end
sys.setHostname = function(hn)hostname = hn end

log("Getting BogoMIPS...")
local st = os.epoch("utc")
local x = 0
local T = 1000000
for i=1, T, 1 do
  x = x + 1
end
local et = os.epoch("utc") - st
local cs = math.floor((T / et)/100)

sysinfo.cpuClock = function()return cs end

log("Running on " .. sysinfo.cpuClock() .. "KHz " .. sysinfo.cpuArch())

log("Setting up kernel API")
local shutdown = os.shutdown  
local reboot = os.reboot
os.shutdown = nil
os.reboot = nil

local open = fs.open -- Avoid the permissions that are setup later

local function uninit()
  log("Saving hostname")
  local h = open("/etc/hostname", "w")
  h.write(sys.hostname())
  h.close()
  log("Logging out")
  users.logout()
end

kernel = {}

function kernel.uname_all()     return kernelUname     end
function kernel.uname_arch()    return kernelArch      end
function kernel.uname_version() return kernelVersion   end
function kernel.uname_name()    return kernelName      end
function kernel.shutdown(opt)
  uninit()
  if opt == "reboot" then
    log("Restarting")
    sleep(0.3)
    reboot()
  else
    log("Shutdown")
    sleep(0.3)
    shutdown()
  end
end

local function findInit()
  local inits = {"/sbin/init.lua","/bin/init.lua","/etc/init.lua"}
  for i=1, #inits, 1 do
    log("Looking for " .. inits[i])
    if fs.exists(inits[i]) then
      return inits[i]
    end
  end
  return false
end

log("Finding init script")
local init = findInit()

if not init then
  kernel_panic("Could not find init script", reboot)
end

log("Found init script at " .. init)

function kernel.run(file, ...)
  local ok, err = loadfile(file)

  if not ok then
    print("Error while running " .. file .. ": " .. err, 0)
    return false
  end

  setfenv(ok, _G)
  ok(...)
end

function error(reason)
  kernel_panic(reason, reboot)
end

local ok, err = loadfile(init)
if not ok then kernel_panic(err, reboot) end

setfenv(ok, _G)
ok(log)
