-- The shell API. Not the shell itself, but just the API. --

local shell = {}

print("Initializing shell API")

local shellPath = {}

prompt = {"__USER__", "@", "__HOSTNAME__", ":", "__DIR__", "#$", " "}

local cd = "/"

local function serialize(t)
  local rtn = ""
  for i=1, #t, 1 do
    rtn = rtn .. t[i]
    if i < #t then
      rtn = rtn .. ", "
    end
  end
end

function shell.path()
  return serialize(shellPath)
end

function shell.currentDir()
  return cd
end

function shell.renderPrompt(p)
  local prompt = p or shell.prompt or prompt
  local rslt = ""
  local function write(str)
    rslt = rslt .. str
  end

  for i=1, #prompt, 1 do
    if prompt[i] == "__USER__" then
      write(users.user() or "")
    elseif prompt[i] == "__HOSTNAME__" then
      write(os.hostname() or "localhost")
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
    
  write(rslt)
end

function shell.setDir(path)
    cd = path
    if path:sub(1,6) == "/ocos/" then
        cd = path:sub(7)
    end
end

function shell.setPath(path)
    if type(path) == "table" then
        shellPath = path
    end
end

function shell.runProgram(program, args)
  if not program then return nil end
  for i=1, #shellPath, 1 do
    if fs.exists(shellPath[i] .. program) then
      return os.run(shellPath[i] .. program)(args)
    end
  end

  errors.programNotFound(program)
  return false
end

function shell.read(replaceChar)
  local str = ""
  
  while true do
    local kp = kb.pullKey()
    if kp.keycode == keys.delete then
      if not str == "" then
        str = str:sub(1,string.len(str)-1)
      end
    elseif kp.keycode == keys.enter then
      break
    else
      str = str .. kp.key
    end

    io.clearLine()
    write((replaceChar or str))
  end

  return str
end

return shell
