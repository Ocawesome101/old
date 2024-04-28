--------------------- OpenNT interface 'cmd': 00_term.lua ----------------------
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
  local term = require("term")
  local component = require("component")
  local ps = require("ex.ps")
  local stdout = {
    read = function()
      error("cannot read from standard output file")
    end,
    write = function(_, d)
      return term.write(d)
    end
  }
  local stdin = {
    read = function(_, ...)
      return term.read(...)
    end,
    write = function()
      error("cannot write to standard input file")
    end
  }
  local function setstdio()
    io.input(stdin)
    io.output(stdout)
    io.error(stdout)
  end
  setstdio()
  io.tmp_stdio = {stdin = stdin, stdout = stdout}
  term.clear()
  io.write("Starting OpenNT...\n")
end
