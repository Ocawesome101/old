-- Lua REPL

local term = ipc.proxy("drv_term")
local gpu = ipc.proxy("drv_gpu")
local serialization = require("serialization")
local ascii = [[
       _
 _____|_|___ ___ ___
|     | |  _|  _| . |
|_|_|_|_|___|_| |___|
]]

term.clear()
print(_VERSION, "Copyright (C) 1994-2017 Lua.org, PUC-Rio")
term.write(ascii)

local LUA_ENV = setmetatable({
  term = ipc.proxy("drv_term"),
  fs = ipc.proxy("drv_fs"),
  import = function(mod)
    shellenv[mod:gsub(" ", ""):gsub("/", "")] = require(mod)
  end,
  unimport = function(mod)
    shellenv[mod] = nil
  end
}, {__index=_G})

while true do
  gpu.setForeground(0x00FF00)
  term.write("lua> ")
  gpu.setForeground(0xFFFFFF)
  local inp = term.read()
  local exec, reason
  if inp:sub(1,1) == "=" then
    exec, reason = load("return " .. inp:sub(2), "=stdin", "t", LUA_ENV)
  else
    exec, reason = load("return " .. inp, "=stdin", "t", LUA_ENV)
    if not exec then
      exec, reason = load(inp, "=stdin", "t", LUA_ENV)
    end
  end
  if exec then
    local result = {pcall(exec)}
    if not result[1] and result[2] then
      print(debug.traceback(result[2]))
    elseif not result[1] then
      print("nil")
    else
      local status, returned = pcall(function() for i = 2, #result, 1 do print(type(result[i]) == "table" and serialization.serialize(result[i]) or result[i]) end end)
      if not status then
        print("error serializing result: " .. tostring(returned))
      end
    end
  else
    print(tostring(reason))
  end
end
