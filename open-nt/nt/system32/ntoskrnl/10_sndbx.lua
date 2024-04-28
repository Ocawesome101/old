----------------------- OpenNT kernel: 10_sandbox.lua --------------------------
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

do
  local sb
  sb = {
    error = error,
    type = type,
    table = nt.ke.tcopy(table),
    rawequal = rawequal,
    load = function(x,n,m,e) return load(x,n,m,e or sb) end,
    loadfile = function(f,n,e) return loadfile(f,n,e or sb) end,
    package = nt.ke.tcopy(package),
    pcall = pcall,
    rawlen = rawlen,
    next = next,
    rawget = rawget,
    _OSVERSION = _OSVERSION,
    select = select,
    pairs = pairs,
    utf8 = utf8 and nt.ke.tcopy(utf8),
    io = nt.ke.tcopy(io),
    checkArg = checkArg,
    tostring = tostring,
    ipairs = ipairs,
    coroutine = nt.ke.tcopy(coroutine),
    _VERSION = _VERSION,
    setmetatable = setmetatable,
    os = nt.ke.tcopy(os),
    getmetatable = getmetatable,
    tonumber = tonumber,
    assert = assert,
    dofile = function(f) return assert(loadfile(f,nil,sb))() end,
    debug = nt.ke.tcopy(debug),
    math = nt.ke.tcopy(math),
    string = nt.ke.tcopy(string),
    rawset = rawset,
    xpcall = xpcall
  }

  sb._G = sb
  sb.table.copy               = nt.ke.tcopy
  sb.package.loaded.computer  = nt.ke.tcopy(computer)
  sb.package.loaded.computer.pullSignal = sb.coroutine.yield
  sb.package.loaded.component = nt.ke.tcopy(component)
  sb.package.loaded.unicode   = nt.ke.tcopy(unicode)
  sb.package.loaded.win32     = nt.ke.tcopy(nt.win32)
  sb.package.loaded["ex.ps"]  = nt.ke.tcopy(nt.ex.ps)
  sb.package.loaded["ex.cm"]  = nt.ke.tcopy(nt.ex.cm)
  sb.package.loaded["ex.ob"]  = nt.ke.tcopy(nt.ex.ob)
  sb.package.loaded.buffer    = nt.ke.tcopy(nt.ex.io)
  sb.package.loaded["ex.lpc"] = nt.ke.tcopy(nt.ex.lpc)
  sb.package.loaded.fs        = nt.ke.tcopy(nt.ke.fs)
  sb.package.loaded.ntconfig  = nt.ke.tcopy(nt.ki.flags)
  local loaded = sb.package.loaded
  function sb.require(name)
    checkArg(1, name, "string")
    if sb.package.loaded[name] then
      return sb.package.loaded[name]
    else
      local path, err = package.searchpath(name, package.path)
      if not path then
        error(string.format("module '%s' not found:\n\tno field package.preload['%s']\n%s", name, name, err))
      end
      local ok, err = loadfile(path, nil, nt.ki.sandbox)
      if not ok then
        error(string.format("error loading module '%s' from file '%s':\n\t%s", name, path, err))
      end
      local ret = ok()
      assert(type(ret) == "function" or type(ret) == "table", string.format("module '%s' returned wrong type (expected 'function' or 'table', got '%s')", name, type(ret)))
      sb.package.loaded[name] = ret
      return ret
    end
  end

  nt.ki.sandbox = sb
end
