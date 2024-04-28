-- System API calls for various OC-OS things --

sys.createMetatable = function(bNoFS) -- Less elegant than the shell's equivalent, but it works.... right?
    local env
    env = _G 
    if bNoFS then
        env.fs = nil
    end
    
    return env
end

sys.runFile = function(path,args,canWrite)
    if not path then
        error("sys.runFile: argument #1 is nil")
        return false
    end

    local runEnv = sys.createMetatable(not canWrite) -- Create a separate table, maybe with no RW capabilities.
    
    if not fs.exists(path) then
        error("sys.runFile: " .. path .. " does not exist")
        return false
    end
    
    return os.run(runEnv, path)
end

sys.run = function(path, args)
    loadfile(path)(args)
end
