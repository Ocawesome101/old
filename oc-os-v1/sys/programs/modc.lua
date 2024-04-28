-- Kernel module controller --

local args = {...}

local modDir = "/sys/modules/"

local available = fs.list(modDir)

if #args ~= 2 or args[1] ~= ("load" or "unload") then
    error("Must specify load/unload and name")
    return false
end

if args[2]:sub(1,1) == "/" then
    error("Modules can only be loaded from preset directory " .. modDir)
    return false
end

if args[1] == "load" then
    log("Searching for module " .. args[2], "info")
    for i=1, #available, 1 do
        if available[i] == args[2] .. ".lua" then
            kernel.loadModule(modDir .. args[2] .. ".lua")
            log("Loaded module", "ok")
            return true
        end
    end
    
    log("Couldn't load module " .. args[2], "err")
    return false
end

if args[1] == "unload" then
    log("Attempting to unload module " .. args[2])
    kernel.unloadModule(args[2])
end
