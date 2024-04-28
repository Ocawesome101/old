-- OC-OS. Rewritten to be better. Sandboxed (in theory). --

local args = {...}

local _version = "OC-OS 0.0.9"

function os.version()
    return _version
end

local function log(msg)
    term.setTextColor(colors.green)
    write("-> ")
    term.setTextColor(colors.yellow)
    print(msg)
    os.sleep(0.01)
end

term.clear()
term.setCursorPos(1,1)
log("OC-OS Sandbox")
log("Initializing OS sandbox...")

local _OS_ENV = {} -- Sandboxing!...ish.

_OS_ENV.osDir = "/ocos/" or args[1]

log(" Injecting core functions...")
_OS_ENV._version = _version
_OS_ENV.print = print
_OS_ENV.write = write
_OS_ENV.panic = error
_OS_ENV.colors = colors
_OS_ENV.read = read
_OS_ENV.os = os
_OS_ENV.fs = fs
_OS_ENV.term = term
_OS_ENV.log = log
_OS_ENV.clearScreen = term.clear
_OS_ENV.len = string.len

log(" Setting up metatable _OS_ENV...")
_OS_ENV._G = _OS_ENV
_OS_ENV._ENV = _OS_ENV

function _OS_ENV.error(msg)
    local oldColor = term.getColor()
    term.setTextColor(colors.red)
    print(msg)
    term.setTextColor(oldColor)
end

log("Initialized sandbox")
log("Starting system")

sleep(0.5)

if not fs.exists(_OS_ENV.osDir .. "sys/core/start.lua") then
    error("Critical system file missing; cannot continue")
end

os.run(_OS_ENV, _OS_ENV.osDir .. "sys/core/start.lua", _OS_ENV.osDir)
