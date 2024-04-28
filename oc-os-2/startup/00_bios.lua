-- Boot selection utility. Place boot scripts in /boot/<name>/ --

local bootDir = "/boot/"

function _G.error(reason)
    local rs = reason or ""

    if not reason then
        rs = "No reason given"
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    
    print("PANIC: " .. rs)
    print("\n" .. os.version() .. " has experienced a critical error.\n")
    sleep(1)
    print("Press any key to reboot")
    os.pullEventRaw("char")
    
    os.reboot()
end

function os.version()
    return "OCBIOS v0.3.1"
end

local function log(msg)
    term.setTextColor(colors.white)
    write("[")
    term.setTextColor(colors.blue)
    write("log")
    term.setTextColor(colors.white)
    print("] " .. msg)
    sleep(0.01)
end

local function getBootables()
    local list = fs.list(bootDir)
    return list
end

local function boot(path)
    log("Booting from " .. bootDir .. path)
    sleep(0.5)
    if fs.exists(bootDir .. path) then
        shell.run(bootDir .. path)
        printError("BIOS Error: Boot script exited without shutting down.\n")
        sleep(1)
        printError("Press any key to reboot")

        os.pullEventRaw("char")

        os.reboot()
   else
        error("Invalid boot path")
   end
end

local function main()
    log("Welcome to " .. os.version())
    local bootables = getBootables()
    log("Looking for bootable devices")
    sleep(1)
    if #bootables < 1 then
        error("No bootable device found")
    end
    if #bootables > 1 then
        print("Please select boot device")

        for i=1, #bootables, 1 do
            print(tostring(i) .. ": " .. bootables[i])
        end
        write("> ")

        local num = (tonumber(read()) or 1000)
        if num > (#bootables or 0) then
            error("Invalid boot device!")
            return nil
        end
        
        boot(bootables[num] .. "/boot.lua")
    else
        boot(bootables[1] .. "/boot.lua")
    end
end

term.clear()
term.setCursorPos(1, 1)

main()
