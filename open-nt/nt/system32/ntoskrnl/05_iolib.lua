-------------------------- OpenNT kernel: 05_io.lua ----------------------------
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
  _G.io = {}
  local buffer = nt.ex.io
  local fs = nt.ke.fs

  local dft = {
    data = {
      io = {
        [0] = {},
        [1] = {},
        [2] = {}
      }
    }
  }

  local rets = {
    stdin = function()
      return (nt.ex.ps.info() or dft).data.io[0]
    end,
    stdout = function()
      return (nt.ex.ps.info() or dft).data.io[1]
    end,
    stderr = function()
      return (nt.ex.ps.info() or dft).data.io[2]
    end
  }

  setmetatable(io, {__index = function(t, k)
    if rets[k] then
      return rets[k]()
    end
  end})

  function io.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    local handle, err = fs.open(file, mode)
    if not handle then
      return nil, err
    end
    return buffer.new(mode, handle)
  end

  local function stream(n, file, m)
    if type(file) == "string" then
      file = assert(io.open(file, m))
    end
    if file then
      (nt.ex.ps.info() or dft).data.io[n] = file
    end
    return (nt.ex.ps.info() or dft).data.io[n]
  end

  function io.input(file)
    checkArg(1, file, "string", "table")
    return stream(0, file, "r")
  end

  function io.output(file)
    checkArg(1, file, "string", "table")
    return stream(1, file, "w")
  end

  function io.error(file)
    checkArg(1, file, "string", "table")
    return stream(2, file, "w")
  end

  function io.type(thing)
    return (type(thing) == "table" and thing.read and thing.write and thing.close and (not thing.closed and "file" or "closed file")) or nil
  end

  function io.write(...)
    return io.stdout:write(...)
  end

  function io.read(...)
    return io.stdin:read(...)
  end

  function io.lines(h, pat)
    checkArg(1, h, "table", "nil")
    h = h or io.stdin
    return h:lines(pat)
  end

  function io.flush(h)
    checkArg(1, h, "table", "nil")
    h = h or io.stdout
    return h:flush()
  end
end

do
  nt.ki.log("Defining loadfile: #3")
  function loadfile(file, mode, env)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    checkArg(3, env, "table", "nil")
    mode = mode or "bt"
    env = env or _G
    local handle, err = io.open(file, "r")
    if not handle then
      return nil, err
    end
    local data = handle:read("a")
    handle:close()
    return load(data, "=" .. file, mode, env)
  end
end
