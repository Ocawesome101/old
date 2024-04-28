local function exec(file, ...) 
    if not fs.exists(file) then
        error(file .. ": File not found")
        return false
    end
    
    local ok, err = loadfile(file)
    if not ok then
        error(err)
        return false
    end
    
    return ok(...)
end

return exec
