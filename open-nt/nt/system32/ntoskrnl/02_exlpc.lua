---------------------- OpenNT kernel: 02_executive_lpc.lua ---------------------
-- OpenNT implementation of the Windows NT Executive's Local Procedure Call.  --
--                                                                            --
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
  local lpc = {}
  local sockets = {}
  local sock_a = {}

  function sock_a:read(n)
    checkArg(1, n, "number")
    if self.closed then
      error("closed socket")
    end
    local timeout = computer.uptime() + self.timeoutA
    while #self.bufferA < n and computer.uptime() < timeout do
      coroutine.yield(0)
    end
    if computer.uptime() >= timeout then
      error("read operation timed out")
    end
    local ret = self.bufferA:sub(1, n)
    self.bufferA = self.bufferA:sub(n + 1)
    return ret
  end

  function sock_a:write(d)
    checkArg(1, d, "string")
    if self.closed then
      error("closed socket")
    end
    self.bufferB = self.bufferB .. d
    return true
  end

  function sock_a:close()
    self.closed = true
  end

  function sock_a:setTimeout(s)
    checkArg(1, s, "number")
    self.timeoutA = s
  end

  local sock_b = {}

  function sock_b:read(n)
    checkArg(1, n, "number", "nil")
    if self.closed then
      error("closed socket")
    end
    local timeout = computer.uptime() + self.timeoutB
    while #self.bufferB < n and computer.uptime() < timeout do
      coroutine.yield(0)
    end
    if computer.uptime() >= timeout then
      error("read operation timed out")
    end
    local ret = self.bufferB:sub(1, n)
    self.bufferB = self.bufferB:sub(n + 1)
    return ret
  end

  function sock_b:write(d)
    checkArg(1, d, "string")
    if self.closed then
      error("closed socket")
    end
    self.bufferA = self.bufferA .. d
  end

  function sock_b:close()
    self.closed = true
  end

  function sock_b:setTimeout(s)
    checkArg(1, s, "number")
    self.timeoutB = s
  end

  -- create a two-way socket connection, sort of like a pipe
  function lpc.socket()
    local s = {timeoutA = math.huge, timeoutB = math.huge, bufferA = "", bufferB = "", closed = false}
    local ts = tostring(s):gsub("table", "socket")
    local amt = {
      __index = sock_a,
      __type = "socket",
      __tostring = function()
        return ts
      end
    }
    local bmt = {
      __index = sock_b,
      __type = "socket",
      __tostring = function()
        return ts
      end
    }
    local a, b = setmetatable(s, amt), setmetatable(s, bmt)
    return a, b
  end

  nt.ex.lpc = lpc
end
