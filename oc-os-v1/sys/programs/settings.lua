-- set --

local args = ...

local usage = [[usage: settings <set/list> ...

settings set <setting> <value>   Apply <value> to <setting>
settings list                    List all settings]]

if not (#args >= 1) then
    printError(usage)
    return false
end

if args[1] == "list" then
    local n = settings.getNames()
    
    for s,v in pairs(n) do
        print(v .. " = " .. tostring(settings.get(v)))
    end
elseif args[1] == "set" then
    if not #args == 3 then
        printError(usage)
        return false
    end
    settings.set(args[2], args[3])
    
    print(args[2] .. " set to " .. settings.get(args[2]))
else
    printError(usage)
end

