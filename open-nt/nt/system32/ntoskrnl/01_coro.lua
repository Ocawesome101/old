----------------------- OpenNT kernel: 01_coroutine.lua ------------------------
-- Override the coroutine API and 'thread' type.                              --
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
  local raw = coroutine
  local coro = {}
  function coro.create(func)
    local new = {}
    local ts = tostring(new):gsub("table", "thread")
    return setmetatable(new, {__type = "thread", __tostring = function() return ts end, __coro = raw.create(func), __index = coro})
  end

  function coro.wrap(func)
    local c = coro.create(func)
    return function(...)
      return assert(c:resume(...))
    end
  end

  function coro:resume(...)
    return raw.resume(getmetatable(self).__coro, ...)
  end

  coro.yield = raw.yield
  
  function coro:isyieldable()
    return raw.isyieldable(getmetatable(self).__coro)
  end

  function coro:status()
    return raw.status(getmetatable(self).__coro)
  end

  function coro.running()
    local r = raw.running()
    local t = {}
    local ts = tostring(r)
    return setmetatable(t, {__index = coro, __coro = r, __tostring = function() return ts end, __type = "thread"})
  end
end
