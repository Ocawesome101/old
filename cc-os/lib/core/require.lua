local requirePath = "/lib/require/"

local function checkFile(file)
    if fs.exists(requirePath .. file) then
        return dofile(requirePath .. file)
    else
        return nil
    end
end

local function require(file)
    local rtn = (checkFile(file) or checkFile(file .. ".lua") or checkFile(file .. "/init.lua"))
    
    if not rtn then
        error("Library does not exist")
    end
    
    if rtn then
        return rtn
    end
    
    return false
end
