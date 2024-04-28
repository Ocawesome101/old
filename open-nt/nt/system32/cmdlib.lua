------------------------------- OpenNT cmdlib.lua ------------------------------
-- Copyright (C) 2020 Ocawesome101                                            --
--                                                                            --
-- This program is free software: you can redistribute it and/or modify       --
-- it under the terms of the GNU General Public License as published by       --
-- the Free Software Foundation, either version 3 of the License, or          --
-- (at your option) any later version.                                        --
--                                                                            --
-- This program is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              --
-- GNU General Public License for more details.                               --
--                                                                            --
-- You should have received a copy of the GNU General Public License          --
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.     --
--------------------------------------------------------------------------------

local cmd = {}

local fs = require("fs")

os.setenv("PATH", os.getenv("PATH") or "A:/NT/System32;A:/NT/System32/Wbem")

function cmd.expand(str)
  for match in str:gmatch("%%[^%%]-%%") do
    str = str:gsub(match:gsub("%%", "%%%%"), os.getenv(match:sub(2, -2)))
  end
  return str
end

function cmd.split(str)
  checkArg(1, str, "string")
  local inblock = false
  local ret = {}
  local cur = ""
  local last = ""
  for char in str:gmatch(".") do
    if char == "'" or char == '"' then
      if inblock == false then inblock = true end
    elseif char == " " then
      if inblock then
        cur = cur .. " "
      elseif cur ~= "" then
        ret[#ret + 1] = cur:gsub("\\27", "\27")
        cur = ""
      end
    else
      cur = cur .. char
    end
    last = char
  end
  if #cur > 0 then
    ret[#ret + 1] = cur:gsub("\\27", "\27")
  end
  return ret
end

function cmd.parse(...)
  local parse = table.pack(...)
  local args, opts = {}, {}
  for i=1, parse.n, 1 do
    local ps = tostring(parse[i])
    if ps:sub(1,1) == "/" and #ps >= 2 then
      local p = ps:sub(2):lower()
      if p:match("(.-):(.-)") then
        local k, v = p:match("(.-):(.-)")
        opts[k] = v
      else
        opts[p] = true
      end
    else
      table.insert(args, ps)
    end
  end
  return args, opts
end

function cmd.execute(c)
  if c:match("^(.):$") then
    if fs.get(c) then
      os.setenv("DRIVE", c)
      os.setenv("CD", "\\")
      return true
    else
      return nil, "Drive " .. c .. " was not found"
    end
  end
  local command = cmd.split(cmd.expand(c))
  local path = os.getenv("PATH")
  local pwd = os.getenv("CD") or "/"
  local exec
  for ent in path:gmatch("[^;]+") do
    if fs.exists(ent .. "/" .. command[1]) then
      exec = ent .. "/" .. command[1]
      break
    elseif fs.exists(ent .. "/" .. command[1] .. ".lua") then
      exec = ent .. "/" .. command[1] .. ".lua"
      break
    end
  end
  if not exec then
    if fs.exists(command[1]) then
      exec = command[1]
    elseif fs.exists(command[1] .. ".lua") then
      exec = command[1] .. ".lua"
    elseif fs.exists(pwd .. "/" .. command[1]) then
      exec = pwd .. "/" .. command[1]
    elseif fs.exists(pwd .. "/" .. command[1] .. ".lua") then
      exec = pwd .. "/" .. command[1] .. ".lua"
    end
  end
  if not exec then
    return nil, "Bad command or file name"
  end
  local ok, err = loadfile(exec)
  if not ok then
    return nil, err
  end
  local stat, ret = pcall(ok, table.unpack(command, 2))
  if not stat and ret then
    return nil, ret
  end
  return true
end

if fs.exists("A:/Autoexec.lua") then
  cmd.execute("A:/Autoexec.lua")
end

return cmd
