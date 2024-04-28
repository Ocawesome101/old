--#@arcpack
--#file:ccemux/install.lua
if not ccemux then
    print('You are not running in CCEmuX. This package cannot be installed.')
    return false
else
    return fs.copy(shell.resolve('./usr/bin/ccemux.lua','/usr/bin/')
end
--#file:ccemux/uninstall.lua
shell.run('rm /usr/bin/ccemux.lua')
--#file:ccemux/usr/bin/ccemux.lua
-- Like the 'emu' command, but for OC Linux --

local usage = [[
CCEmuX version]] .. ccemux.getVersion() .. [[ by the CCEmuX Team

Usage:
ccemux open [number]    number is optional
ccemux data             open ccemux data directory
ccemux config           open ccemux configuration
ccemux version          print ccemux version
]]

local args = {...}

if #args < 1 then print(usage) return nil end

if args[1] then local op = args[1] end
if args[2] then local num = tonumber(args[2]) end

if op == 'open' then
    if num then
        ccemux.openEmu(num)
    else
        ccemux.openEmu(os.getComputerID()+1)
    end
    return true
end

if op == 'data' then ccemux.openDataDir() return true

elseif op == 'version' then print(ccemux.getVersion()) return true

elseif op == 'config' then ccemux.openConfig() return true

else print(usage) return true end

