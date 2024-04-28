-------------------------- OpenNT shell32: 00_gdi.lua --------------------------
-- Graphics Device Interface - manage buffers and soon draw lines, squares.   --
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

-- TODO: Support for multiple / dynamic GPUs (screens too?) and possibly HW buffers across multiple GPUs, with one screen

do
  local gdi = {}
  local gpu = require("component").gpu
  local bufs = {}
  -- Hardware buffers are cheaper, faster, and have more operations available.
  -- Software buffers are more expensive, slower, and have fewer operations available, but are not limited by the GPU.
  gdi.HW_RW_PERSIST = 1024 -- hardware buffer, will be frequently changed, should persist
  gdi.HW_WO_PERSIST = 2048 -- hardware buffer, will be written to once and not changed, should persist. For static windows.
  gdi.HW_WO_TEMP    = 4096 -- hardware buffer, will be written to once, should be overwritten / destroyed if necessary. This is the default mode.
  gdi.SW_RW_PERSIST = 8192 -- software buffer, RW_PERSIST, not recommended except for small buffers
  gdi.SW_WO_PERSIST = 16384 -- software buffer, WO_PERSIST, should only be used for small buffers as software buffers are expensive

  local swbufN = 0
  
  local context = require("ex.ob").new("scrbuf")

  function context:blit(x, y)
    checkArg(1, x, "number")
    checkArg(2, y, "number")
    if self.type == "hardware" then
      gpu.bitblt(0, x, y, nil, nil, self.index)
    elseif self.type == "software" then
      local fg, bg
      for X=x, x + self.w do
        for Y=y, y + self.h do
          local c, f, b = self.comp.get(X - x + 1, Y - y + 1)
          if fg ~= f then
            gpu.setForeground(f)
            fg = f
          end
          if bg ~= b then
            gpu.setBackground(b)
            bg = b
          end
          gpu.set(X, Y, c)
        end
      end
    end
  end

  -- Software buffers do not support copy operations.
  local function createSoftwareBuffer(mode, w, h)
    local buf = {}
    for i=1, w, 1 do
      local t = {}
      for n=1, h, 1 do
        buf[i][n] = {fg = 0x000000, bg = 0xFFFFFF, char = " "}
      end
      buf[i] = setmetatable(t, {__index = function(_, n) return {} end})
    end
    setmetatable(buf, {__index = function(_, n) return {} end})
    local lib = {}
    local fg, bg = 0x000000, 0xFFFFFF

    function lib.setBackground(c)
      checkArg(1, c, "number")
      bg = c
      return true
    end

    function lib.getBackground()
      return bg
    end

    function lib.setForeground(c)
      checkArg(1, c, "number")
      fg = c
      return true
    end

    function lib.getForeground()
      return fg
    end

    function lib.get(x, y)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      local char = buf[x][y]
      return char.char, char.fg, char.bg
    end

    function lib.set(x, y, s, v)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      checkArg(3, s, "string")
      checkArg(4, v, "boolean", "nil")
      if v then -- set vertically
        for Y=y, y + unicode.len(s) do
          local c = buf[x][Y]
          c.char = unicode.sub(s, Y - y + 1)
          c.fg = fg
          c.bg = bg
        end
      else -- set horizontally
        for X=x, x + unicode.len(s) do
          local c = buf[X][y]
          c.char = unicode.sub(s, Y - y + 1)
          c.fg = fg
          c.bg = bg
        end
      end
      return true
    end

    function lib.fill(x, y, w, h, c)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      checkArg(3, w, "number")
      checkArg(4, h, "number")
      checkArg(5, c, "string")
      if unicode.len(c) > 1 then
        return nil, "invalid fill value"
      end
      for X=1, x + w do
        for Y=1, y + h do
          local C = buf[X][Y]
          C.char = c
          C.fg = fg
          C.bg = bg
        end
      end
      return true
    end

    return lib
  end

  -- creates a basic "proxy" of sorts, which supports all basic GPU operations
  local function createHardwareBufferInterface(mode, index, w, h)
    local lib = {}
    local ops = {
      getBackground = true,
      setBackground = true,
      getForeground = true,
      setForeground = true,
      get           = true,
      set           = true,
      copy          = true,
      fill          = true
    }
    local function invoke(op, ...)
      if not ops[op] or not gpu[op] then
        return nil, "invalid operation: " .. op
      end
      local old = gpu.getActiveBuffer()
      gpu.setActiveBuffer(index)
      local result = table.pack(pcall(gpu[op], ...))
      gpu.setActiveBuffer(old)
      if not result[1] then
        return nil, result[2]
      else
        return table.unpack(result, 2)
      end
    end

    for op, _ in pairs(ops) do
      lib[op] = function(...)
        return invoke(op, ...)
      end
    end

    function lib.maxResolution()
      return w, h
    end

    return lib
  end

  function gdi.createContext(mode, w, h)
    checkArg(1, mode, "number", "nil")
    checkArg(2, w, "number", "nil")
    checkArg(3, h, "number", "nil")
    mode = mode or gdi.HW_WO_TEMP
    w = w or 50
    h = h or 16
    if mode <= gdi.HW_WO_TEMP and gpu.freeMemory then -- hardware buffer if supported
      if gpu.freeMemory() < w * h then
        for index, buffer in pairs(bufs) do
          if buffer.type == gdi.HW_WO_TEMP then
            gpu.freeBuffer(index)
          end
        end
      end
      local bufIndex = gpu.allocateBuffer(w, h)
      local buffer = context:clone()
      buffer.type = "hardware"
      buffer.w = w
      buffer.h = h
      buffer.comp = createHardwareBufferInterface(mode, bufIndex, w, h)
      buffer.index = bufIndex
      bufs.hardware[bufIndex] = buffer
    else -- software buffer
      local buffer = context:clone()
      local bufIndex = 1024 + swbufN
      swbufN = swbufN + 1
      buffer.type = "software"
      buffer.w = w
      buffer.h = h
      buffer.comp = createSoftwareBuffer(mode, w, h)
      buffer.index = bufIndex
      buf.software[bufIndex] = buffer
    end

    return buffer
  end

  -- inject win32.gdi
  require("win32").gdi = gdi
end
