-- The OS kernel. Responsible for many things, such as loading libraries. --

-- It is generally a good idea, for compatibility's sake, to define _OSVERSION. Note the ommission of the `local` keyword.
_G._OSVERSION = "mini 0.1.0"

-- Find the addresses of one installed GPU and one installed screen. Methods can be called on component addresses through component.invoke or you can create a proxy with component.proxy
local gpu = component.list("gpu")()
local screen = component.list("screen")()

-- Example of using component.invoke.
component.invoke(
  gpu,    -- The component address, a string
  "bind", -- The method you want to invoke. Must be valid, and must be a string.
  screen  -- Any additional arguments are interpreted as parameters
)

-- Create a component proxy for the GPU and the boot filesystem.
local gpuProxy = component.proxy(gpu)
_G.fs = component.proxy(computer.getBootAddress())

-- Here we set up basic boot logging.
local line = 1 -- What line are we on?
local width, height = gpuProxy.maxResolution() -- get the maximum resolution of the GPU and screen. These values are the minimum of the two.
gpuProxy.setResolution(width, height) -- ensure that the screen resolution is properly set
gpuProxy.fill( -- Fill a box on-screen with a single character
  1,      -- The top-left X coordinate
  1,      -- The top-left Y coordinate
  width,  -- How wide the box should be
  height, -- How tall the box should be
  " "     -- The character the box should be made of
)
local function log(message)
  -- checkArg is a very useful function, used for argument checking.
  checkArg(
    1,        -- the argument number
    message,  -- the argument itself
    "string"  -- one or more types that are allowed for the argument, in the form of separate strings.
  )
  
  -- Set the line at
  gpuProxy.set( -- Set a line (or part of a line) onscreen to a string
    1,       -- The X coordinate of the string
    line,    -- The Y coordinate of the string
    message  -- The string
  )
  
  if line == height then -- We can't go down or we'll be off the screen, so scroll down a line
    gpuProxy.copy( -- Copy one screen area to another
      1,        -- The top-left X coordinate
      1,        -- The top-left Y coordinate
      width,    -- The width
      height,   -- The height
      0,        -- The relative X to copy to
      -1        -- The relative Y to copy to
    )
    gpuProxy.fill(1, height, width, 1, " ")
  else
    line = line + 1 -- Move one line down
  end
end

-- Crash the system in a slightly prettier fashion. Not necessary, but nice to have.
local function crash(reason)
  checkArg(1, reason, "string", "nil") -- This is an example of checkArg's ability to check multiple types
  -- Here, reason is already local; there is no need to specify it so
  reason = reason or "No reason given"
  log("==== crash " .. os.date() .. " ====") -- Log the crash header, ex. "==== crash 24/04/20 18:52:34 ===="
  log("crash reason: " .. reason) -- Log the crash reason. ".." is Lua's string concatenation operator.
  local traceback = debug.traceback() -- Tracebacks are usually useful for debugging
  traceback = traceback:gsub("\t", "  ") -- Replace the tab character (not printable) with spaces (printable)
  for line in traceback:gmatch("[^\n]+") --[[ :gmatch("[^\n]+") splits the string on the \n (newline) character using Lua's basic regular expressions ]] do
    log(line)
  end
  log("==== end crash message ====")
  while true do -- Freeze the system
    computer.pullSignal()
  end
end

log("Starting " .. _OSVERSION)

-- Uncomment the line below to see what the crash function does
-- crash("Demo crash")


-- Set up a proper usable environment
log("Loading APIs")

-- loadfile
function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  -- Make sure mode and env are set
  mode = mode or "bt"
  env  = env or _G -- env can be used for sandboxing. Quite useful.
  
  local handle, err = fs.open(file, "r")
  if not handle then
    return nil, err
  end
  
  local data = ""
  repeat
    local fileChunk = fs.read(handle, math.huge)
    data = data .. (fileChunk or "")
  until not fileChunk
  
  fs.close(handle) -- Always close your file handles, kids
  
  return load(data, "=" .. file, mode, env)
end

-- dofile
function _G.dofile(file)
  checkArg(1, file, "string")
  local ok, err = loadfile(file)
  if not ok then
    return nil, err
  end
  return ok()
end

-- To disable library caching (useful for debugging) comment out the lines with "--" after them. What is a comment, you ask? This is a comment: a line preceded by "--".
--[[
Multiline and
in-line
comments
work
as
well.
]]
-- Tables are useful things.
local libPaths = { -- The path(s) to search for libraries
  "/mini/lib/?.lua",
  "/ext/lib/?.lua"
}

local loaded = { ["gpu"] = gpuProxy } -- Libraries that have already been loaded

-- require
function _G.require(lib)
  checkArg(1, lib, "string")
  if loaded[lib] then   --
    return loaded[lib]  --
  else                  --
    -- It wasn't already loaded, so search all the paths
    for i=1, #libPaths, 1 do
      component.proxy(component.list("sandbox")()).log(libPaths[i]:gsub("%?", lib))
      if fs.exists(
        libPaths[i] -- The current path
          :gsub( -- Replace a character or characters in a string with another string
            "%?", -- The string to replace. "%" is necessary because string.gsub, string.gmatch, and string.match interpret "?", along with a few other patterns, as a form of regex (DuckDuckGo regular expressions if you don't know what regex is).
            lib -- The string with which to replace "?"
          )
        ) then
        local ok, err = dofile(string.gsub(libPaths[i], "%?", lib)) -- string.gsub("stringToGSUB", ...) is the same as ("stringToGSUB"):gsub(...)
        if not ok then
          error(err)
        end
        loaded[lib] = ok  --
        return ok
      end
    end
  end             --
end

log("Starting shell")

while true do
  local ok, err = dofile("/mini/shell.lua") -- Run the shell
  if not ok then
    crash(err)
  end
end
