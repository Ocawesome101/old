-- OC Package Manager, CC edition --

local args = {...}

local base = 'https://raw.githubusercontent.com/'

local src = {}

local function getlists()
    if not fs.exists('/var/lib/ocpm/lists/' .. src[1]) then
        print('Error: no package lists found. Try running ocpm update.')
        return false
    end
    
    local lists = {}

    for i=1, #src do
        local file = dofile('/var/lib/ocpm/lists/'.. src[i] ..'/packages.lua')
        if file then
            table.insert(lists,file)
        end
        i = i + 1
    end
    return lists
end

local function getinst()
    if fs.exists('/var/lib/ocpm/installed') then
        local fileraw = fs.open('/var/lib/ocpm/installed')
        local file = textutils.unserialize(fileraw.readAll())
        return file
    else
        print('No packages are registered with OCPM.')
        return
    end
end

local function getdepends(pkg)
    if pkg.depends ~= nil then
        for i=1, #pkg.depends do
            print('undefined')
            i = i + 1
        end
    end
end

local function inst(package)
    local installed = getinst()
    local available = getlists()
    for i=1, #installed do
        if installed[i] == package then
            print('Package is already installed')
            return true
        end
        i = i + 1
    end
    
    for i=1, #available do
        if available[i][package] then
            local f = available[i][package]
            if not getdepends(f) then
                print('Error: unable to resolve dependencies')
            end
            local raw = http.get(base .. f.repo .. '/master/' .. f.name)
            if raw ~= ('' or nil) then
                local file = raw.readAll()
                raw.close()
                local fileraw = fs.open('/var/cache/ocpm/packages/' .. f.name,'w')
                fileraw.write(file)
                fileraw.close()
            else
                print('Error: Package not found')
                return false
            end
        end
    end
end

local function update()
    local srcraw = fs.open('/etc/ocpm/sources','r')
    src = textutils.serialize(srcraw.readAll())
    srcraw.close()
    for i=1, #src do
        print('Getting list from ' .. src[i])
        local listraw = http.get(base .. src[i] .. '/master/packages.lua')
        if not listraw or listraw == '' then
            print('Error: no list in repo' .. src[i])
            print('Please remove it from /etc/ocpm/sources')
            return
        end
        
        local list = listraw.readAll()
        listraw.close()
        local fileraw = fs.open('/var/lib/ocpm/lists/'..src[i]..'packages.lua','a')
        fileraw.write(list)
        fileraw.close()
        i = i + 1
    end
    print('Got lists')
end

local function query(package)
    local files = getlists()

    for i=1, #files do
        if files[i][package] then
            return true
        end
        i = i + 1
    end
    return false
end

local function install(package)
    local files = getlists()
    for i=1, #files do
        if files[i][package] then
            local r = inst(package)
            return r 
        end
        i = i + 1
    end
    return false
end

local function getdepends(pkg)
    if pkg.depends ~= nil then
        for i=1, #pkg.depends do
            if not install(pkg.depends[i]) then
                return false
            end
            i = i + 1
        end
    end
    
    return true
end

local function remove(package)
    local instfiles = getinst()
    for i=1, #instfiles do
        if instfiles[i] == package then
            shell.run('/var/lib/ocpm/' .. package .. '/uninstall.lua')
            print('Package uninstalled')
            return true
        end
        i = i + 1
    end
    return false
end

local usage = [[
OCPM v0.02 by Ocawesome101

Usage:
ocpm update
ocpm <install | remove | query> <package>
]]

if #args < 1 then print(usage) return end
if args[1] then op = args[1] end
if args[2] then pkg = args[2] end

if op == 'install' then
    if pkg then
        install(pkg)
    end
elseif op == 'remove' then
    if pkg then
        remove(package)
    end
elseif op == 'update' then
    update()
elseif op == 'query' then
    if pkg then
        query(pkg)
    end
end

