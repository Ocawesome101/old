------------------------ OpenNT kernel: 05_package.lua -------------------------
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

_G.package = {}

package.path = "A:/NT/System32/?.lua;A:/Program Files/?/init.lua;A:/Program Files/Common/?.lua"
local fs = nt.ke.fs
local loaded, loading = {}, {}
package.loaded = loaded

local function libErr(src)
  local err = ""
  for i=1, #src, 1 do
    err = string.format("%s\tno file '%s'\n", err, src[i])
  end
  return err
end

function package.searchpath(name, path, sep, rep)
  checkArg(1, name, "string")
  checkArg(2, path, "string")
  checkArg(3, sep, "string", "nil")
  checkArg(4, rep, "string", "nil")
  sep = "%" .. (sep or ".")
  rep = rep or "/"
  local searched = {}
  for try in path:gmatch("[^;]+") do
    name = name:gsub(sep, rep)
    try = try:gsub("%?", name)
    if fs.exists(try) then
      return try
    end
    table.insert(searched, try)
  end
  return nil, libErr(searched)
end

function require(name)
  checkArg(1, name, "string")
  if loaded[name] then
    return loaded[name]
  else
    local path, err = package.searchpath(name, package.path)
    if not path then
      error(string.format("module '%s' not found:\n\tno field package.loaded['%s']\n%s", name, name, err))
    end
    local ok, err = loadfile(path, nil, nt.ki.sandbox)
    if not ok then
      error(string.format("error loading module '%s' from file '%s':\n\t%s", name, path, err))
    end
    local ret = ok()
    assert(type(ret) == "function" or type(ret) == "table", string.format("module '%s' returned wrong type (expected 'function' or 'table', got '%s')", name, type(ret)))
    package.loaded[name] = ret
    return ret
  end
end
