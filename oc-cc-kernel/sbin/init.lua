-- Init script --

local log = ...
local lib = "/lib/"

if require then
  print("You cannot run init as it is already running.")
  return nil
end

local function printStylized(...)
  local args = {...}
  for i=1, #args, 1 do
    if type(args[i]) == "number" then
      setTextColor(args[i])
    elseif type(args[i]) == "string" then
      write(args[i])
    end
  end
  write("\n")
end

print("")

printStylized(colors.white, "Welcome to ", colors.lightBlue, "oc-cc-kernel", colors.white, "!")

print("")

log("Reading configuration from /etc/init.conf")
local ok, err = loadfile("/etc/init.conf")

if not ok then
  error("Could not load /etc/init.conf")
end

log("Setting hostname")
local h = fs.open("/etc/hostname", "r")
sys.setHostname(h.readLine())
h.close()

local apis = ok()

for i=1, #apis, 1 do
  log("Loading " .. apis[i])
  local ok, err = loadfile(lib .. apis[i])
  if not ok then log("WARNING: Could not load " .. apis[i] .. " from " .. lib .. apis[i])
  else setfenv(ok, _G); ok() end
end

log("Starting login screen")
kernel.run("/bin/login.lua")
