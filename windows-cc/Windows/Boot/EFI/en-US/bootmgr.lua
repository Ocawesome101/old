-- Windows Boot Manager --

local function tui(items)
    term.setBackgroundColor(colors.lightBlue)
    local item = 1
    while true do
        term.setCursorPos(2,2)
        for i=1, #items, 1 do
            term.setCursorPos(2, i + 1)
            if i == item then
                print("-> " .. items[i])
            else
                print("   " .. items[i])
            end
        end
        local event = {os.pullEvent()}
        if event[1] == "key" then
            if event[2] == keys.up then
                if item > 1 then item = item - 1 end
            elseif event[2] == keys.down then
                if item < #items then item = item + 1 end
            elseif event[2] == keys.enter then
                return item
            end
        end
    end
end

local function menu()
    while true do
        local items = {"Start Windows normally", "Recovery Options", "Shut Down"}
        local i = tui(items)
        if i == 1 then
            break
        elseif i == 2 then
            local items = {"Command Prompt", "Restart", "Back"}
            local opt = tui(items)
            if opt == 1 then
                dofile("/rom/programs/shell.lua")
            elseif opt == 2 then
                os.reboot()
            end
        elseif i == 3 then
            os.shutdown()
        end
    end
    
    return true
end

function _G.bsod(err)
    local bsodTemplate = [[
    A problem has been detected and Windows has been shut down to prevent damage to your computer.
    
    If this is the first time you've seen this Stop error screen, restart your computer. If this screen appears again, follow these steps.
    
    Check to make sure any new hardware or software is properly installed. If this is a new installation, ask your hardware or software manufacturer for any Windows updates you might need.
    ]]
    
    term.setBackgroundColor(colors.blue)
    term.clear()
    term.setCursorPos(1,1)
    print("***STOP: " .. err)
    print(bsodTemplate)
end

local function boot_win()
    local path = "/Windows/System32/winload.lua"
    local ok, err = loadfile(path)
    if not ok then
        bsod(err)
        while true do
            os.pullEvent()
        end
        return
    end
    
    ok()
end

if _G.recoveryPossible then
    if menu() then
        boot_win()
    end
end

boot_win()

