-- OC-OS Kernel --

log("Booting kernel", "ok")

local function panic(reason,details)
    if not reason then reason = "No reason given" end
    
    printError("Kernel Panic: " .. reason)
    if details then
        printError("Details: " .. details)
        local log = fs.open("/sys/log/panic.log","w")
        log.write(details)
        log.close()
        printError("\nDetails have been logged to /sys/log/panic.log")
    end
    printError("\nPress any key to reboot")
    os.pullEventRaw("char")
    
    os.reboot()
end

local function loadModule(path)
    log("Loading core kernel module from " .. path)
    local ok, err = loadfile(path)
    
    if not ok then panic("Failed to load module", err) end
    
    ok(panic)
end

local modules = fs.list("/sys/kernel/coremodules/")

for i=1, #modules, 1 do
    loadModule("/sys/kernel/coremodules/" .. modules[i])
end

log("Running " .. kernel.version() .. " on " .. cpu.clockSpeed() .. "KHz " .. cpu.arch() .. " processor")

sys.run("/sys/programs/shell.lua")
