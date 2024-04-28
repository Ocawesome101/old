-- Login system for OC-OS --

local loginPrompt = {"__HOSTNAME__", " login: "}
local passwordPrompt = {"password: "}

while true do
    while true do
        shell.renderPrompt(loginPrompt)
        local name = shell.read()
        shell.renderPrompt(passwordPrompt)
        local pswd = shell.read("")
        if users.login(name, pswd) then break end
    end
    if fs.exists("/programs/oc-shell.lua") then
        run("/programs/oc-shell.lua")
    else
        errors.fileNotFound("/programs/oc-shell.lua")
    end
end
