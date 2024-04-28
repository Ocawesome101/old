-- Shell API for OC-OS

local shellPath = {}

prompt = {"__USER__", "@", "__HOSTNAME__", ":", "__DIR__", "#$", " "}

local cd = "/"

function path()
    return textutils.serialize(shellPath)
end

function currentDir()
    return cd
end

function renderPrompt(p)
    local prompt = p or shell.prompt or prompt

    for i=1, #prompt, 1 do
        if prompt[i] == "__USER__" then
            write(users.user() or "")
        elseif prompt[i] == "__HOSTNAME__" then
            write(net.hostname() or "localhost")
        elseif prompt[i] == "__DIR__" then
            write(cd or "")
        elseif prompt[i] == "#$" then
            if users.user() == "root" and users.uid() == 0 then
                write("#")
            else
                write("$")
            end
        else
            write(prompt[i])
        end
    end
end

function setDir(path)
    cd = path
    if path:sub(1,6) == "/ocos/" then
        cd = path:sub(7)
    end
end

function setPath(path)
    if type(path) == "table" then
        shellPath = path
    end
end

function runProgram(program, args)
    for i=1, #shellPath, 1 do
        if fs.exists(shellPath[i] .. program) then
            return run(shellPath[i] .. program, args)
        end
    end

    errors.programNotFound(program)
    return false
end
