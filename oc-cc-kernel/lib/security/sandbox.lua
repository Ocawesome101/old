-- Sandboxing tools --

local sandbox = {}

local function tcopy(tbl)
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
end

function sandbox.setupSandbox(has)
  local hasOS, hasFS, hasFenv = has.hasOS, has.hasFS, has.hasFenv

  local sandboxEnv = {}
  if hasOS then
    sandboxEnv.os = tcopy(os)
    sandboxEnv.os.version = function()
      return nil
    end
  end
  if hasFS then
    sandboxEnv.fs = tcopy(fs)
  end
  sandboxEnv.load = load
  sandboxEnv.loadstring = loadstring
  sandboxEnv.loadfile = loadfile
  if hasFenv then
    sandboxEnv.setfenv = setfenv
    sandboxEnv.getfenv = function(arg)
      local tge = getfenv(arg)
      return tge
    end
  end
  sandboxEnv.pcall = pcall
  sandboxEnv.xpcall = xpcall
  sandboxEnv.select = select
  sandboxEnv.next = next
  sandboxEnv.type = type
  sandboxEnv.string = string
  sandboxEnv.table = table
  sandboxEnv.tostring = tostring
  sandboxEnv.tonumber = tonumber
  sandboxEnv.math = math
  sandboxEnv.write = write
  sandboxEnv.clearLine = function()
    term.clearLine()
  end
  sandboxEnv.setTextColor = function(color)
    term.setTextColor(color)
  end
  sandboxEnv.getTextColor = function(color)
    return term.getTextColor()
  end
  sandboxEnv.setBackgroundColor = function(color)
    term.setBackgroundColor(color)
  end
  sandboxEnv.getBackgroundColor = function()
    return term.getBackgroundColor()
  end
  sandboxEnv.setPaletteColor = function(color, ...)
    term.setPaletteColor(color, ...)
  end
  sandboxEnv.getPaletteColor = function(color)
    return term.getPaletteColor(color)
  end
  sandboxEnv.setCursorPos = function(x,y)
    term.setCursorPos(x,y)
  end
  sandboxEnv.getCursorPos = function()
    return term.getCursorPos()
  end
  sandboxEnv.colors = tcopy(colors)
  sandboxEnv._G =   sandboxEnv
  sandboxEnv._ENV =   sandboxEnv

  return sandboxEnv
end

function sandbox.runWithSandbox(sandboxEnv, program, ...)
  local prg, err = loadfile(program)
  if prg then
    setfenv(prg, sandboxEnv)
    prg(...)
  else
    errors.programInaccessibleError(program)
  end
end

return sandbox
