-- sh. Will possible eventually support pipes, shebangs, and shell scripts --

local args = {...}

if sh then args = sh.parse(args) end

local sh = {}
local users = dofile("/lib/users.lua")
local errors = dofile("/lib/errors.lua")
local net = dofile("/lib/net.lua")

local exit = false

local vars = {
  PWD = users.homeDir() or "/",
  HOME = users.homeDir(),
  USER = users.user(),
  UID = users.uid(),
  ["PS1"] = "\\u@\\h: \\w\\$ ",
  ["PS2"] = ">",
  ["PS3"] = "",
  ["PS4"] = "+",
  PATH = "/bin:/usr/bin:/sbin:/usr/local/bin:/usr/games",
  HOSTNAME = net.hostname(),
  PS_COLOR = colors.white,
  TEXT_COLOR = colors.white
}

local builtins = {
  echo = function(...)
    print((... or ""))
  end,
  cd = function(...)
    local args = {...}
    
    local dir = (args[1] or users.homeFolder())
    if fs.exists(dir) then
      sDir = dir
    else
      errors.noSuchFile(dir)
      return 1
    end
  end,
  exit = function()
    exit = true
  end
}

local function createIterable(tTable) -- Create an iterable from a table - i.e. make {"1", "2", "3"} into something similar to fileHandle:lines()
  local i = 1
  local rtn = function()
    if i < #tTable + 1 then
      r = tTable[i]
      i = i + 1
      return r
    end
  end
  
  return rtn
end

function sh.parse(tArgs)
  local tRtn = {}

  local iArgs = createIterable(tArgs)

  for item in iArgs do
    if item:sub(1,1) == "$" and item:len() > 1 then
      item = item:sub(2)
      for k,v in pairs(vars) do
        if k == item then
          table.insert(tRtn, v)
          found = true
        end
        if not found then
          table.insert(tRtn, "")
          found = false
        end
      end
    elseif item:sub(1,1) == "~" then
      item = users.homeDir() .. item:sub(2)
      table.insert(tRtn, item)
    else
      table.insert(tRtn, item)
    end
  end

  return tRtn
end     

local function parsePS(ps) -- Parse the PS* variables (PS1, PS2, PS4)
  local psa = {}
  local i = 1
  local opt = ""
  while true do
    opt = ps:format():sub(i,i)
    if opt == "\\" then
      local a = ps:format():sub(i+1,i+1)
      if a == "u" then
        table.insert(psa, "$USER")
      elseif a == "h" then
        table.insert(psa, "$HOSTNAME")
      elseif a == "$" then
      	local prompt = "$"
      	if vars.USER == "root" then
      	  prompt = "#"
      	end
        table.insert(psa, prompt)
      elseif a == "w" then
        table.insert(psa, "$PWD")
      end
      i = i + 2
    else
      table.insert(psa, opt)
      i = i + 1
    end
    if i > #ps:format() then
      break
    end
  end

  local rtn = ""
  local t = sh.parse(psa)
  for i=1, #t, 1 do
    local a = t[i]
    if a:sub(1,#users.homeDir()) == users.homeDir() then
      a = "~" .. a:sub(#users.homeDir()+1)
    end
    rtn = rtn .. a
  end

  return rtn
end

local function tokenize(...)
  local sLine = table.concat( { ... }, " " )
  local tWords = {}
  local bQuoted = false
  for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
    if bQuoted then
      table.insert( tWords, match )
    else
      for m in string.gmatch( match, "[^ \t]+" ) do
        table.insert( tWords, m )
      end
    end
    bQuoted = not bQuoted
  end
  return tWords
end

local function path() -- Turn $PATH into a table for easier parsing later
  local rtn = {}
  for path in string.gmatch(vars.PATH, "[^:]+") do
    table.insert(rtn, path)
  end

  return rtn   
end

local function run(file, args)
  local ok, err = loadfile(file)
  if not ok then
    printError(err)
    return
  end

  local ok, err = pcall(ok, table.unpack(args))
  if not ok then
    printError(err)
  end
end

function sh.run(...)
  local args = {...}
  local iPaths = createIterable(path())
  
  local cmd = args[1]
  
  table.remove(args, 1)
  
  for k,v in pairs(builtins) do
    if k == cmd then
      return v(table.unpack(args))
    end
  end

  for path in iPaths do
    if fs.exists(cmd) then
      run(cmd)
    end
  end
end

while not exit do
  term.setTextColor(vars.PS_COLOR)
  write(parsePS(vars.PS1))
  term.setTextColor(vars.TEXT_COLOR)
  local command = read()

  if command ~= "" then
    sh.run(table.unpack(tokenize(command)))
  end
end
