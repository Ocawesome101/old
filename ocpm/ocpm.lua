-- OCPM, a simple but functional package manager for OC Linux --

local args = {...}

local urlResolvers = { -- 3-letter shortcuts for much longer URLs
   ["git:"] = {
       resolveTo = "https://raw.githubusercontent.com/" 
   },
   
   ["ozc:"] = {
       resolveTo = "https://oz-craft.pickardayune.com/"
   }
}

local pmDirs = {
    "/var/cache/ocpm/packages/",
    "/var/cache/ocpm/lists/",
    "/tmp/",
    "/etc/ocpm/"
}

local pkgDir = pmDirs[1]
local listDir = pmDirs[2]
local tmpDir = pmDirs[3]

local listFile = pmDirs[4] .. "sources.list" -- package sources

local function require(path)
    if not fs.exists(path) then
        print("E: Path " .. path .. " does not exist.")
        return nil
    end
    local handle = fs.open(path, "r")
    local file = handle.readAll()
    handle.close()
    local data = loadstring(file)()
    return data
end

local function get(sUrl) -- Ripped straight from wget.lua
    local ok, err = http.checkURL(sUrl)
    if not ok then
        print( "Failed: " .. (err or " no reason given") .. ".")
        return nil
    end

    local response = http.get(sUrl, nil, true)
    if not response then
        print("Failed.")
        return nil
    end

    local sResponse = response.readAll()
    response.close()
    return sResponse
end

local function writeTo(sData, sPath)
    local handle = fs.open(sPath, "w")
    handle.write(sData)
    handle.close()
end

local function resolveURL(url)
    print("Resolving URL...")
    local retURL = url
    local firstFour = retURL:sub(1,4)
    if urlResolvers[firstFour] then
        retURL = urlResolvers[firstFour].resolveTo .. retURL:sub(5)
    end
    if urlResolvers[firstFour].suffix then
        retURL = retURL .. urlResolvers[firstFour].suffix
    end
    return retURL
end

local function checkDirs() -- Check for required directories
    print("Checking for existence of package manager directories...")
    for i=1, #pmDirs, 1 do
        if not fs.exists(pmDirs[i]) then
            fs.makeDir(pmDirs[i])
        end
    end
end

local function checkArc()
    print("Checking for existence of package manager required archiver...")
    if not fs.exists("/usr/bin/arc.lua") then
        local arc = get("https://pastebin.com/VdJMpxkS")
        writeTo(arc, "/usr/bin/arc.lua")
    end
end

local function addRepo(repoURL) -- i.e. addRepo('git:ocawesome101/ocpm/packages')
    local full_url = resolveURL(repoURL)
    checkDirs()
    if not get(full_url .. "packages.list") then
        print("E: Provided repository either does not exist or does not have a packages.list file.")
        return nil
    end
    write("Add repository " .. repoURL .. "? [y/n]: ")
    local add = read()
    if add:lower() == "y" then
        local repoList = fs.open(listFile, "a")
        repoList.write(full_url)
        repoList.close()
    else
        print("Aborting.")
    end
end

local function getLists()
    local retList = {}
    local items = fs.list(listDir)

    for i=1, #items, 1 do
        print("Found list " .. listDir .. items[i])
        local tmp = require(listDir .. items[i])
        for j=1, #tmp, 1 do
            table.insert(retList, tmp[j])
        end
    end
    return retList
end

local function resolveDepends(pkgData)
    if not pkgData.depends then
        print("No dependencies to resolve.")
        return nil
    end
    
    local rtn = {}
    
    for i=1, #pkgData.depends, 1 do
        table.insert(rtn, pkgData.depends[i])
    end
    
    return rtn
end

local function splitLines(fileHandle)
    local retList

    for line in fileHandle:lines() do
        table.insert(retList, line)
    end
    
    return retList
end

local function getInstalled()
    local raw = fs.open(pmDirs[4] .. "installed.list", "r")
    local rtn = splitLines(raw)
    raw.close()
end


local function registerPkg(name, mode)
    local pkgRegs = getInstalled()

    if mode == nil or mode == "add" then
        table.insert(pkgRegs, name)
        writeList(pkgRegs, pmDirs[4] .. "installed.list")
    elseif mode == "sub" then
        for i=1, #pkgRegs, 1 do
            if pkgRegs[i] == name then
                pkgRegs[i] = nil
            end
        end
    end
end

local function installPackage(name)
    print("Installing package " .. name)
    checkDirs()
    checkArc()
    local list = getLists()
    if list == {} or #list == 0 then
        print("E: Package list(s) are missing or empty. Try running ocpm update.")
        return nil
    end
    
    if not list[name] then
        print("E: Package not found.")
        return nil
    end
    
    local pkg = list[name]
    
    print("Resolving dependencies...")
    local depends = resolveDepends(pkg)
    
    print("The following packages will be installed:")
    
    local toInstall = {}
    
    if depends then
        for i=1, #depends, 1 do
            write(depends[i] .. " ")
            table.insert(toInstall, depends[i])
        end
        write("\n")
    end
    
    table.insert(toInstall, name)
    print(name)
    
    write("Install" .. tostring(#toInstall) .. " packages? [Y/n]: ")
    
    if string.lower(read()) == "n" then
        print("Aborting.")
        return nil
    end
    
    for i=1, #toInstall, 1 do
        local pkgURL = resolveURL(list[toInstall[i]].downloadURL)
        local data = get(pkgURL)
        writeTo(data, pkgDir .. toInstall[i] .. ".arc")
    end
    
    for i=1, #toInstall, 1 do
        shell.run("/usr/bin/arc x " .. toInstall[i] .. " " .. tmpDir)
        if not fs.exists(tmpDir .. toInstall[i] .. "/install.lua") then
            print("E: Package " .. toInstall[i] .. " has no install.lua.")
            return nil
        end
        
        if not fs.exists(tmpDir .. toInstall[i] .. "/uninstall.lua") then
            print("E: Package " .. toInstall[i] .. " has no uninstall.lua.")
        end
        
        shell.run(tmpDir .. toInstall[i] .. "/install.lua")
        
        print("Registering package " .. toInstall[i])        
        registerPkg(toInstall[i], "add")
    end
    
    return true
end

local function updateLists()    
    local i = 1
    for line in io.lines(listFile) do
        print("Download:" .. tostring(i) .. ": " .. line .. "/packages.list")
        local list = get(line .. "/packages.list")
        if list == "" or not list then
            print("E: Repo " .. line .. " has no packages.list file")
            return nil
        end
        writeTo(list, listDir .. "list_" .. tostring(i) .. ".list")
        i = i + 1
    end
end

local function removePackage(name)
    print("Removing package " .. name)
    checkArc()
    print("Getting installed packages...")
    local installed = getInstalled()
    
    local toRemove = {}
    
    for i=1, #installed, 1 do
        if installed[i] == name then
            table.insert(toRemove, name)
        end
    end
    
    if toRemove == {} then
        print("E: Package " .. name .. " is not installed.")
        return nil
    end
    
    if not fs.exists(tmpDir .. toRemove[1]) then
        shell.run("/usr/bin/arc x " .. pkgDir .. toRemove[1] .. " " .. tmpDir)
        shell.run(tmpDir .. toRemove[1] .. "/uninstall.lua")
    end

    registerPkg(name, "sub")
end

local function usage()
    print([[ OCPM v0.2.7 by Ocawesome101
    
    Usage:
    
    ocpm <install | remove> <package>  Install or remove a package 
    ocpm update                        Refresh package lists
    ocpm addrepo <url>                 Add a package repository
    ]])
end

local function parseArgs(tArgs)
    if tArgs[1] == "update" then
        updateLists()
    elseif tArgs[1] == "addrepo" then
        if tArgs[2] then
            addRepo(tArgs[2])
        else
            usage()
        end
    elseif tArgs[1] == "install" then
        if tArgs[2] then
            installPackage(tArgs[2])
        else
            usage()
        end
    elseif tArgs[1] == "remove" then
        if tArgs[2] then
            removePackage(tArgs[2])
        else
            usage()
        end
    else
        usage()
    end
end

parseArgs(args)
