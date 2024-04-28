-- Simple help system --

local oses = {"oc-cc-kernel", "CC-OS"}
local users = {"ocawesome101", "ocawesome101"} -- Could potentially add others later, if anyone actually develops for this thing lol
local instCodes = {"NVDXKaZF", nil}

local function menu(tItems)
    local selected = 1
    while true do
        term.clear()
        term.setCursorPos(3,2)
        print("CC-BIOS Help")
        for i=1, #tItems, 1 do
            if i == selected then
                print("> " .. tItems[i])
            else
                print("  " .. tItems[i])
            end
        end
        local e, id = os.pullEvent("key")
        if id == keys.enter then
            return selected
        elseif id == keys.up then
            if selected > 1 then
                selected = selected - 1
            end
        elseif id == keys.down then
            if selected < #tItems then
                selected = selected + 1
            end
        end
    end
end

while true do
    local item = menu({"Reboot","Shutdown","Shell","Advanced"})
    if item == 1 then
        os.reboot()
    elseif item == 2 then
        os.shutdown()
    elseif item == 3 then
        loadfile("/rom/modules/shell/shell.lua")()
    elseif item == 4 then
        local advanceditem = menu({"Download and install CC-OS", "Back"})
        if advanceditem == 1 then
            local data = http.get("https://pastebin.com/raw/s3baJBuq")
            local exec = loadstring(data.readAll())
            data.close()
            local choice = menu({"OC-CC-Kernel (Recommended, stable)","OC-CC-Kernel (Root only)" , "CC-OS (Heavily WIP)"})
            if choice == 1 then
              local data = http.get("https://pastebin.com/raw/NVDXKaZF")
              local exec = loadstring(data.readAll())
              data.close()
              exec()
            end
            exec(users[choice], oses[choice+1])
        end
    end
end
