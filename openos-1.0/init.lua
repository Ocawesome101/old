computer.romAddress = computer.getBootAddress
local function bootstrap()
  -- Minimalistic hard-coded pure async proxy for our ROM.
  local rom = {}
  function rom.invoke(method, ...)
    return component.invoke(computer.romAddress(), method, ...)
  end
  function rom.open(file) return rom.invoke("open", file) end
  function rom.read(handle) return rom.invoke("read", handle, math.huge) end
  function rom.close(handle) return rom.invoke("close", handle) end
  function rom.libs(file) return ipairs(rom.invoke("list", "lib")) end
  function rom.isDirectory(path) return rom.invoke("isDirectory", path) end

  -- Custom low-level dofile implementation reading from our ROM.
  local function dofile(file)
    local handle, reason = rom.open(file)
    if not handle then
      error(reason)
    end
    if handle then
      local buffer = ""
      repeat
        local data, reason = rom.read(handle)
        if not data and reason then
          error(reason)
        end
        buffer = buffer .. (data or "")
      until not data
      rom.close(handle)
      local program, reason = load(buffer, "=" .. file, "t", sandbox)
      if program then
        local result = table.pack(pcall(program))
        --if result[1] then
          return table.unpack(result, 2, result.n)
        --else
          --error(result[2])
        --end
      else
        error(reason)
      end
    end
  end

  local init = {}
  for _, lib in rom.libs() do
    local path = "lib/" .. lib
    if not rom.isDirectory(path) then
      local install = dofile(path)
      if type(install) == "function" then
        table.insert(init, install)
      end
    end
  end

  for _, install in ipairs(init) do
    install()
  end
end
bootstrap()
fs.mount(computer.romAddress(), "/")
if computer.tmpAddress() then fs.mount(computer.tmpAddress(), "/tmp") end

for c, t in component.list() do
  computer.pushSignal("component_added", c, t)
end
os.sleep(0.5) -- Allow signal processing by libraries.

term.clear()

while true do
  local result, reason = os.execute("/bin/sh -v")
  if not result then
    print(reason)
  end
end
