-- Core APIs for OC-OS --

-- print, write, error, panic, len, getColor, setColor, setCursorPos, getCursorPos, log, fs.*, os.*, clearScreen are here

local args = {...}
osDir = args[1]

function os.version()
    return _version
end

clearScreen()
term.setCursorPos(1,1)
log("Booting " .. os.version())

log("Cleaning up term API")
local t = term
_G.term = nil

for i=1, #t, 1 do
    table.insert()
end

log("Registering path resolver")
function os.resolvePath(path)
    local rtn = osDir .. path

    return rtn
end

local resolvePath = os.resolvePath

log("Loading errors API")

os.loadAPI(osDir .. "/sys/apis/errors.lua")

log("Registering system-protected folders")
local protected = {
    osDir .. "sys/",
    osDir .. "sys/core/",
    osDir .. "programs/",
    "/sys/",
    "/sys/core/",
    "/programs/"
}

log("Wrapping fs.open in preparation for multiuser")

local nativeOpen = fs.open

function fs.open(f, mode)
    local file = resolvePath(f)
    local root = false
    for i=1, #protected, 1 do
        if file:sub(1, len(protected[i])) == protected[i] then
            root = true
        end
    end
    if root then
        if users.user() == "root" and users.uid() == 0 then
            local h = nativeOpen(file, mode)
            return h
        else
            errors.accessDenied()
            return nil
        end
    else
        local h = nativeOpen(file, mode)
        return h
    end
end

log("Wrapping fs.exists for sandboxing purposes")

local nativeExists = fs.exists

function fs.exists(p)
    local path = resolvePath(p)
    if nativeExists(path) then
        return true
    else
        return false
    end
end

log("Wrapping fs.list")

local nativeList = fs.list

function fs.list(dir)
    local path = resolvePath(dir)
    if fs.exists(dir) then
        return nativeList(path)
    else
        return {""}
    end
end

log("Initializing run()")

function run(file, args)
    if fs.exists(file) then
        os.run(_G, file, args)
    else
        errors.fileNotFound(file)
        return nil
    end
end

log("Initializing networking: check for HTTP, set hostname")

if not http then
    errors.APINotFound("HTTP")
end

os.loadAPI("/sys/apis/net.lua")

if fs.exists("/sys/hostname") then
    local h = fs.open("/sys/hostname", "r")
    net.setHostname(h.readLine())
    log("Set hostname to " .. net.hostname())
    h.close()
else
    log("/sys/hostname not found. Setting hostname to ocos")
    net.setHostname("ocos")
end

log("Initializing user subsystem")
os.loadAPI("/sys/apis/users.lua")

log("Initializing shell API")
os.loadAPI("/sys/apis/shell.lua")

if not shell then panic("The OC-OS Shell API could not be loaded") end

log("Initializing login system")

run("/programs/login.lua")
