--------------------------- OpenNT kernel: 00_fs.lua ---------------------------
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
  nt.ki.log("Setting up drives")
  local drives = {
    A = component.proxy(computer.getBootAddress()),
    T = component.proxy(computer.tmpAddress())
  }

  local driveletters = {
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  }

  local fs = {}

  local function resolve(path)
    path = path:gsub("\\", "/")
    local letter, file = path:match("^(.):(.*)")
    letter = letter or ((nt.ex.ps.info() or {data={env={DRIVE="A:"}}}).data.env.DRIVE or "A:"):sub(1,1)
    file = file or path
    file = file:lower()
    letter = letter:upper()
    if not drives[letter] then
      return nil, "drive "..letter..":/ does not exist"
    end
    return drives[letter], file
  end

  local function fread(s, n)
    return s.fs.read(s.handle, n)
  end
  
  local function fwrite(s, d)
    return s.fs.write(s.handle, d)
  end

  local function fseek(s, w, o)
    return s.fs.seek(s.handle, w, o)
  end

  local function fclose(s)
    return s.fs.close(s.handle)
  end

  local open = {}

  function fs.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string", "nil")
    mode = mode or "r"
    local prx, path = resolve(file)
    if not prx then
      return nil, path
    end
    local handle, err = prx.open(path, mode)
    if not handle then
      return nil, err
    end
    local ret = {
      fs = prx,
      handle = handle,
      read = fread,
      write = fwrite,
      seek = fseek,
      close = fclose
    }
    open[#open + 1] = ret
    return ret
  end

  function fs.close_handles()
    for i=1, #open, 1 do
      open[i]:close()
    end
  end

  function fs.canonical(path)
    local seg = {}
    for s in path:gmatch("[^/]+") do
      if s == ".." then
        table.remove(seg, #seg)
      elseif s ~= "." then
        table.insert(seg, s)
      end
    end
    return table.concat(seg, "/")
  end

  function fs.mount(comp)
    checkArg(1, comp, "string", "table")
    if type(comp) == "string" then comp = assert(component.proxy(comp)) end
    for i=1, #driveletters, 1 do
      if not drives[driveletters[i]] then
        drives[driveletters[i]] = comp
        return driveletters[i]
      end
    end
    return nil, "Too many drives mounted"
  end

  function fs.mounts()
    local d = {}
    for k,v in pairs(drives) do
      d[v.address] = k
    end
    return d
  end

  function fs.unmount(drv)
    checkArg(1, drv, "string")
    drv = drv:sub(1, 1):upper()
    if not drives[drv] then
      return nil, "Drive " .. drv .. ":/ does not exist"
    end
    drives[drv] = nil
    return true
  end

  local function basic(o)
    return function(a)
      checkArg(1, a, "string")
      local prx, path = resolve(a)
      if not prx then
        return nil, path
      end
      return prx[o](path)
    end
  end

  fs.makeDirectory = basic("makeDirectory")
  fs.isDirectory = basic("isDirectory")
  fs.exists = basic("exists")
  fs.remove = basic("remove")
  fs.size = basic("size")
  fs.lastModified = basic("lastModified")
  fs.list = basic("list")

  function fs.rename(old, new)
    checkArg(1, old, "string")
    checkArg(2, new, "string")
    local oprx, opath = resolve(old)
    local nprx, npath = resolve(new)
    if oprx.address == nprx.address then -- same physical disk
      return oprx.rename(opath, npath)
    else
      local ok, err = fs.copy(old, new)
      if not ok then return nil, err end
      return fs.remove(old)
    end
  end

  function fs.copy(from, to)
    checkArg(1, from, "string")
    checkArg(2, to, "string")
    local fprx, fpath = resolve(from)
    local tprx, tpath = resolve(to)
    if fprx.isDirectory(fpath) then
      return nil, "Cannot copy a directory"
    end
    local inh, err = fs.open(from, "r")
    if not inh then
      return nil, err
    end
    local out, err = fs.open(to, "w")
    if not out then
      inh:close()
      return nil, err
    end
    repeat
      local chunk = inh:read(math.huge)
      if chunk then out:write(chunk) end
    until not chunk
    inh:close()
    out:close()
    return true
  end

  function fs.get(drv)
    checkArg(1, drv, "string")
    drv = drv:sub(1, 1):upper()
    return drives[drv] or nil, "Drive " .. drv .. ":/ does not exist"
  end

  function fs.concat(...)
    return (table.concat(table.pack(...), "\\"):gsub("([/\\]+)", "\\"))
  end

  nt.ke.fs = fs
end
