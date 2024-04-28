-- term API

local cx, cy = 1, 1
local gpu = sys.gpu or setmetatable({}, {__index = function() return function() return 1, 1, 1, 1, 1, 1, 1, 1, 1 end end})
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
local term = {}

local function chkcpos()
  local w, h = gpu.getResolution()
  if cx > w then
    cx, cy = 1, cy + 1
  end

  if cy > h then
    gpu.copy(1, 1, w, h, 0, -1)
    gpu.fill(1, h, w, 1, " ")
    cy = h
  end

  if cx < 1 then cx = w cy = cy - 1 end
  if cy < 1 then cy = 1 end
end

local function write(s)
  local w, h = gpu.getResolution()
  while #s > 0 do
    chkcpos()
    local ln = s:sub(1, w - cx + 1)
    s = s:sub(#ln + 1)
    gpu.set(cx, cy, ln)
    cx = cx + #ln
  end
end

function term.write(str, ...)
  checkArg(1, str, "string")
  str = string.format(str, ...)
  str = str:gsub("\t", "    ")
  for char in str:gmatch(".") do
    if char == "\n" then
      cx, cy = 1, cy + 1
      chkcpos()
    else
      write(char)
    end
  end
end

local chars = {
  [200] = "^A",
  [203] = "^D",
  [205] = "^C",
  [208] = "^B",
}

function term.read()
  local buf = ""
  local sx, sy = cx, cy
  local function redraw()
    local w, h = gpu.getResolution()
    cx, cy = sx, sy
    write(buf .. "_ ")
    while ((#buf + sx) // w) + sy > h do
      sy = sy - 1
    end
  end
  while true do
    redraw()
    local sig, _, char, code = coroutine.yield()
    if sig == "key_down" then
      if char > 31 and char < 127 then
        buf = buf .. string.char(char)
      elseif chars[code] then
        buf = buf .. chars[code]
      elseif char == 8 then
        buf = buf:sub(1, -2)
      elseif char == 13 then
        cx, cy = sx, sy
        write(buf .. " ")
        term.write("\n")
        return buf
      end
    elseif sig == "clipboard" then
      buf = buf .. char
    end
  end
end

function term.cursor(x, y)
  checkArg(1, x, "number", "nil")
  checkArg(2, y, "number", "nil")
  if x and y then
    cx, cy = x, y
    chkcpos()
  else
    return cx, cy
  end
end

function term.clear()
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

-- module definitions
local mod = {}

function mod.load()
  _G.term = term
  function printf(fmt, ...)
    checkArg(1, fmt, "string")
    return term.write(fmt, ...)
  end
  function print(fmt, ...)
    checkArg(1, fmt, "string")
    return term.write(fmt.."\n", ...)
  end
end

-- XXX IMPORTANT XXX
-- This module should *NEVER* be unloader, so no
-- 'mod.unload' definition is provided. For non-
-- essential modules, a 'mod.unload' function
-- should be provided.

return mod
