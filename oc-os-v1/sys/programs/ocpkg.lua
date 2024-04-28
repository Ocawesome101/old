-- Package manager --

local listDir = "/data/ocpm/lists/"
local srcList = "/data/ocpm/sources.list"
local insList = "/data/ocpm/installed.list"
local pkgDir = "/data/ocpm/dl/pkg/"

local usage = [[Usage:

  ocpkg install <package>                install package <package>.
  
  ocpkg addrepo <repo>                   add a package repository. git://user/repo/branch can be used for GitHub repositories.

  ocpkg remove <package>		 remove package <package>.

  ocpkg update				 update ocpkg's package lists

]]

local sCuts = {
    {
        name = "git://",
        fullUrl = "https://raw.githubusercontent.com/"
    }
}

local function get(url)
    if not http.checkURL(url) then
        printError(url .. " is not valid")
        return false
    end
    
    local rawData = http.get(url)
    
    if not rawData then
        printError(url .. " does not seem valid")
        return false
    end
    
    local data = rawData.readAll()
    
    rawData.close()
    
    return data
end

local function writeTo(data, file)
    local f = fs.open(file, "a")
    f.write(data)
    f.close()
end

local function updateLists()
    local raw = fs.open(srcList, "r")
    local repo = raw.readLine()
    local i = 1
    while repo do
        local data = get(repo)
        if not data then repo.close(); return false end
        writeTo(data, "/data/ocpm/lists/list_" .. tostring(i) .. ".list")
        repo = raw.readLine()
        i = i + 1
    end
    repo.close()
    return true
end

local function readLists()
    local rtn = {}
    
    local list = fs.list(listDir)
    for i=1, #list, 1 do
        local ok, err = loadfile(listDir .. list[i])
        if not ok then printError(err); return false end
        
        local ls = ok()
        
        table.insert(rtn, ls)
    end
    
    return rtn
end

local function addRepo(repo)
    local f = repo:sub(1,4)
    local r = repo
    for i=1, #sCuts, 1 do
        if f == sCuts[i].name then
            r = sCuts[i].fullUrl .. r:sub(5) .. "/"
        end
    end
    
    writeTo(srcList, r)
    return true
end

local function getInstalled()
    local raw = fs.open(insList, "r")
    
    local lines = {}
    local line = (raw.readLine() or nil)
    while line do
        table.insert(lines, line)
        i = i + 1
    end
    return lines
end

local function isInstalled(name)
    local inst = (getInstalled() or {""})
    
    for i=1, #inst, 1 do
        if inst[i] == name then
            return true
        end
    end
    return false
end

local function install(pkgData)
    local data = get(pkgData.downloadURL)
    
    if not data then
        printError("Package could not be downloaded")
        return false
    end
    
    writeTo(data, pkgDir .. pkgData.name .. ".lua")
    
    local ok, err = loadfile(pkgDir .. pkgData.name .. ".lua")
    
    if not ok then
        printError(err)
        return false
    end
    
    local pkgFuncs = ok()
    
    if (not pkgFuncs.install) or (not pkgFuncs.uninstall) then
        printError("Package is missing install or uninstall"
        return false
    end
    
    assert(pkgFuncs.install(), "Failed to install package")
    
    writeTo(insList, pkgData.name)
    
    return true
end

local function installPackage(name)
    if isInstalled(name) then
        log("Package " .. name .. " is already installed.")
        return true
    end

    local lists = readLists()
    
    if not lists then printError("Call to readLists() failed"); return false end
    
    for i=1, #lists, 1 do
        local list = lists[i]
        
        for n=1, #list, 1 do
            if list[n].name == name then
                return install(list[n])
            end
        end
    end
    
    return false
end
