----------------------- OpenNT kernel: 03_loadfile.lua -------------------------
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
  function loadfile(file, mode, env)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    checkArg(3, env, "table", "nil")
    mode = mode or "bt"
    env = env or _G
    local handle, err = nt.ke.fs.open(file, "r")
    if not handle then
      return nil, err
    end
    local data = ""
    repeat
      local chunk = handle:read(math.huge)
      data = data .. (chunk or "")
    until not chunk
    handle:close()
    return load(data, "=" .. file, mode, env)
  end

  function dofile(file)
    checkArg(1, file, "string")
    return assert(loadfile(file))() -- assert() is a wonderful thing
  end
end
