-- Boot script, OC-OS --

function _G.log(msg,status) -- Simpler log function
    local c = 0 
    if (status == ("info" or nil)) or (not status) then c = colors.lightBlue 
    elseif status == "ok" then c = colors.green 
    elseif status == "warn" then c = colors.orange 
    elseif status == "err" then c = colors.red 
    end
    sys.log((status or "info"),(c or colors.lightBlue),msg)
    sleep(0.01)
end

log("Loading kernel")

local x, y = term.getCursorPos()

term.setCursorPos(24,y-1)

textutils.slowPrint(".......................")

loadfile("/sys/kernel/main.lua")()
