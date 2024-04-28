-- Simple boot script. --

term.clear()
term.setCursorPos(1,1)

os.sleep(0.1)

local function log(msg) -- So many questions why this is necessary
    print(msg)
    os.sleep(0.0001)
end

log("Booting CC-OS on " .. _HOST)

log("Getting boot options")
local bootOpts = dofile("/boot/bootopts.cfg")

log("Loading APIs:")

local tApis = fs.list("/lib/boot/")

for i=1, #tApis, 1 do
    log(tApis[i])
    os.loadAPI("/lib/boot/" .. tApis[i])
end

log("Getting rid of os.loadAPI; require is used from here on.")

os.loadAPI = function()
    error("Use require(), not os.loadAPI()!")
end

os.unloadAPI = function()
    error("Use require() instead of (un)loadAPI()")
end

_G.require = dofile("/lib/core/require.lua")

local ok, err = pcall( function()
    if scheduler and not bootOpts.noScheduler then
        log("Using cooperative task scheduler")
        _G.exec = dofile("/lib/core/exec_scheduler.lua")
        scheduler.add(exec("/bin/login.lua"))
        scheduler.init()
    else
        log("Cooperative multitasking is disabled. Entering single-user-mode shell.")
        _G.exec = dofile("/lib/core/exec_noscheduler.lua")
        exec("/sbin/sushi.lua")
    end
end )

if not ok then
    printError(err)
end

os.sleep(1)
