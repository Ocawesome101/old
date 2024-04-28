-- A basic shell --

local cmdHistory = {}

local exit = false

shell.setPath({"/programs"})

shell.setDir(users.homeDir(users.user()))

local function tokenize(...) -- Ripped straight from the CraftOS shell cause it's useful
    local sLine = table.concat({...}, " ")
    local tWords = {}
    local bQuoted = false
    for match in string.gmatch(sLine .. "\"", "(.-)\"") do
        if bQuoted then
            table.insert(tWords, match)
        else
            for m in string.gmatch(match, "[^ \t]+") do
                table.insert(tWords, m)
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

local function runBuiltin(cmd, args)
    local builtins = {
        {
            name = "exit",
            func = function()
                exit=true
            end
        },
        {
            name = "ls",
            func = function(tArgs)
                local arg = (tArgs[1] or shell.currentDir())
                if arg == ".." then
                    cd = cd .. ".."
                end
                local files = fs.list(dir)
                for i=1, #files, 1 do
                    print(files[i])
                end
            end
        },
        {
            name = "shutdown",
            func = function()
                users.logout()
                os.shutdown()
            end
        }
    }
    for i=1, #builtins, 1 do
        if builtins[i].name == cmd then
            builtins[i].func(args)
            return true
        end
    end
end

while not exit do
    shell.renderPrompt()
    local runMe = read(nil, cmdHistory)

    runMe = tokenize(runMe)

    local cmd = runMe[1]
    local args = {}

    for i=2, #runMe, 1 do
        table.insert(args, runMe[i])
    end

    if not runBuiltin(cmd, args) then
        shell.runProgram(cmd, args)
    end
end
