-- A basic but functional shell --

local path = {
    "/sys/programs/",
    "/programs/"
}

local prompt = "ocos::"
local exit = false

local dir = "/"

_G.shell = {}

shell.setDir = function(d)
    if d:sub(1,1) ~= "/" then
        d = "/" .. d 
    end
    if fs.exists(d) then
        dir = d
        return true
    else
        printError(d .. " does not exist")
        return false
    end
end

shell.dir = function()
    return dir
end

local builtins = {
    {
        name = "exit",
        func = function(tArgs)
            exit = true
            os.exit()
        end
    },
    {
        name = "cd",
        func = function(args)            
            if args[1] then
                if not fs.exists(args[1]) then
                    printError(args[1] .. " does not exist")
                else
                    shell.setDir(args[1])
                end
            else
                print(shell.dir())
                return false
            end
        end
    }
}

local function execute(prog, tArgs)
    local ok, err = loadfile(prog)
    if not ok then printError(err); return false end
    
    ok(tArgs)
end

local function separate(...) -- Separate input into words
    local line = table.concat({...}, " ")
    local tWords = {}
    local bWhatDoesThisDo = false
    for match in string.gmatch(line .. "\"", "(.-)\"") do
        if bWhatDoesThisDo then
            table.insert(tWords, match)
        else
            for m in string.gmatch(match, "[^ \t]+") do
                table.insert(tWords, m)
            end
        end
        bWhatDoesThisDo = not bWhatDoesThisDo
    end

    return tWords
end

local function checkBuiltin(cmd, args)
    for i=1, #builtins, 1 do
        if builtins[i].name == cmd then
            builtins[i].func(args)
            return true
        end
    end
end

local function resolve(name)
    for i=1, #path, 1 do
        if fs.exists(path[i] .. name .. ".lua") then
            return path[i] .. name .. ".lua"
        elseif fs.exists(path[i] .. name) then
            return path[i] .. name
        end
    end
    
    return "/v8ASdfNSJDjSSDfpsdpfsKEnfsesneOASdoiasdfosokDKfSDJIOAsdpaoeK___TestFileThatShouldNeverExist"
end

local function parse(input)
    local tCmds = separate(input)
    
    local args = {}
    
    local b = tCmds[1]
    tCmds[1] = nil
    
    for i=2, #tCmds, 1 do
        table.insert(args, tCmds[i])
    end
    
    local bltin = checkBuiltin(b, args)
    
    if not bltin then
        local cmd = resolve(b)
    
        if not fs.exists(cmd) then
            printError(b .. ": Command not found")
            return nil
        end
    
        execute(cmd, args)
    end
end

while not exit do
    write(prompt .. shell.dir() .. " > ")
    local c_in = read()
    if c_in ~= ("" or nil) then
        parse(c_in)
    end
end
