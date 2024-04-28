-------------------------------- OpenNT lua.lua --------------------------------
-- Quick, hacky Lua REPL.                                                     --
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
local env = setmetatable({}, {__index=_G})
local run = true
env.exit = function()
  run = false
end
print("Type exit() to exit.")
while run do
  io.write("> ")
  local ok,err = load(io.read(), nil, nil, env)
  if not ok then
    print(err)
  else
    print(pcall(ok))
  end
end
