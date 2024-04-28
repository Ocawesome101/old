-- A completely custom BIOS for CC: Tweaked. Loads OSes from disk. --

-- expect
do
  local type = type
  function _G.expect(n, have, ...)
    assert(type(n) == "number", "bad argument #1 to 'expect' (number expected, got "..type(n)..")")
    have = type(have)
    local function check(want, ...)
      if not want then
        return false
      else
        return have == want or check(...)
      end
    end
    if not check(...) then
      error(string.format("bad argument #%d (%s expected, got %s)", n,
                                table.concat(table.pack(...), " or "), have), 3)
    end
  end
end

-- Lua 5.2 maybe 5.3 things, remove loadstring
if _VERSION == "Lua 5.1" then
  local nload, nloadstr, nsfenv = load, loadstring, setfenv
  
  function load(x, name, mode, env)
    expect(1, x, "string", "function")
    expect(2, name, "string", "nil")
    expect(3, mode, "string", "nil")
    expect(4, env, "table", "nil")
    local res, err
    if type(x) == "string" then
      res, err = nloadstr(x, name)
    else
      res, err = nload(x, name)
    end
    if res then
      if env then
        env._ENV = env
        nsfenv(res, env)
      end
      return res
    else
      return nil, err
    end
  end
  
  table.unpack = table.unpack or unpack
  table.pack = table.pack or function(...) return {n = select("#", ...), ...} end
  
  _G.getfenv, _G.setfenv, _G.loadstring, _G.unpack, _G.math.log10, _G.table.maxn = nil, nil, nil, nil, nil, nil
  
  if bit then -- replace bit with bit32
    local nbit = bit
    _G.bit32 = {}
    bit32.arshift = nbit.brshift
    bit32.band = nbit.band
    bit32.bnot = nbit.bnot
    bit32.bor = nbit.bor
    bit32.btest = function(a, b) return nbit.band(a, b) ~= 0 end
    bit32.bxor = nbit.bxor
    bit32.lshift = nbit.blshift
    bit32.rshift = nbit.blogic_rshift
    _G.bit = nil
  end
end

-- I have chosen to omit os.* and globals

local function loadfile(filename)
  local f, e = fs.open(filename, "r")
  if not f then return nil, e end
  local ret = f.readAll()
  f.close()
  return load(ret, "="..filename, "bt", _G)
end

function term.set(x, y, str)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, str, "string")
  term.setCursorPos(x, y)
  term.write(str)
end

term.clear()
term.set(1, 1, "+----+")
term.set(1, 2, "| OC | OC-BIOS version 0.0.1")
term.set(1, 3, "|    | Copyright (c) 2020 Ocawesome101")
term.set(1, 4, "+----+")

term.set(1, 6, "Looking for bootable media")

local bootPath = "/"

do
  local function checkDisk(dn)
    if fs.exists("disk"..dn) then
      term.set(1, 8, "Found disk: /disk"..dn)
      return "/disk"..dn
    end
    return false
  end
  term.set(1, 7, "Checking first 10 disks")
  bootPath = checkDisk("") or bootPath
  for i=1, 10, 1 do
    bootPath = checkDisk(i) or bootPath
  end
  if bootPath == "/" then
    term.set(1, 8, "No disks found")
  end
end

function os.getBootPath()
  return bootPath
end

term.set(1, 9, "Booting " .. fs.combine(bootPath, "startup.lua"))
local ok, err = loadfile(fs.combine(bootPath, "startup.lua"))
if ok then
  ok, err = pcall(ok)
end
if not ok then
  term.set(1, 9, "ERR: "..err)
end

while true do coroutine.yield() end
