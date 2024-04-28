-- Kernel calls --

local panic = ...

log("Loading core kernel functions", "info")

local k = {}

k.version = function()
    return "OC Kernel 0.7.1 build 1156"
end

local cpu = {} -- "CPU" info API

local function getClock() -- Get effective CPU clock speed
    local ct = {}
    local cc = 10
    
    for i=1, cc do
        local clock = os.clock()
        local stop = clock + (1/cc)
        local c = 0
        while clock < stop do
            clock = os.clock()
            c = c + 1
        end
        table.insert(ct,c)
    end
    
    local t = 0
    for k,v in pairs(ct) do
        t = t + v 
    end
    
    local function rd(va,pl)
        return math.floor((va/pl) + 0.5)*pl
    end
    
    local avg = t/cc
    local hz = avg*20
    local khz = rd((hz/1000),0.001)
    
    return khz
end

log("Getting approximate CPU clock speed","ok")
local clockSpeed = getClock()

cpu.clockSpeed = function()return clockSpeed end

log("Getting CPU architecture","ok")
cpu.fullbit = function()return term.isColor() end

local arch
if cpu.fullbit() then
    arch = "CC51-64"
else
    arch = "CC51-32"
end

cpu.arch = function()return arch end

cpu.info = function()
    return {
        clock = cpu.clockSpeed(),
        is64bit = cpu.fullbit(),
        arch = cpu.arch()
    }
end

log("Injecting cpu info into _G")
_G.cpu = cpu

local halt = os.shutdown 
os.shutdown = nil

local reset = os.reboot 
os.reboot = nil

k.shutdown = function()
    log("Shutting down")
    os.sleep(1)
    halt()
end

k.reboot = function()
    log("Restarting")
    os.sleep(1)
    reset()
end

k.cpuInfo = function()
    return cpu.info()
end

local loaded = {}

local function name(path)
    local i = path:len()
    if path:sub(i) == "/" then
        if i == 1 then
            error("Cannot run name() on root directory")
            return false
        else
            i = i - 1
            path = path:sub(1,i)
        end
    end
    while path:sub(i) ~= "/" do
        i = i - 1
    end
    
    return path:sub(i+1) -- ish
end

k.loadModule = function(mod)
    log("Attempting to load kernel module from " .. mod)
    if not fs.exists(mod) then
        error("Failed to load kernel module")
        return false 
    end
    
    log("Checking if the module errors")
    local ok, err = loadfile(mod)
    if not ok then
        error(err)
        return false
    end
    
    log("Attempting to execute loaded module", "ok")
    
    assert(ok(), "Failed to execute loaded module")
    
    table.insert(loaded,name(mod))
    
    return true
end

k.queryModule = function(mod, I)
    for i=1, #loaded, 1 do
        if loaded[i] == mod then
            if I then return i end
            return true
        end
    end
    
    return false
end

k.unloadModule = function(mod)
    if not k.queryModule(mod) then
        error("Cannot unload module " .. mod .. ": not loaded")
        return false
    end
    
    local id = k.queryModule(mod,true)
    
    _G[mod] = nil -- Ouch
    loaded[id] = nil
    return true
end

_G.kernel = k 

log("Loaded core kernel functions", "ok")
