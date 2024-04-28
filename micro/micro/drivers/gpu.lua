-- gpu driver --

local component, computer = component, computer
local gpus, screens = {}, {}

local gpu, screen

local function update()
  if not gpu then
    if #gpus > 0 then
      gpu = component.proxy(gpus[1])
    end
  end
  if gpu and #screens > 0 then
    if not gpu.getScreen() then
      gpu.bind(screens[1])
    end
  end
end

for addr, _ in component.list("gpu") do
  gpus[#gpus + 1] = addr
end

for addr, _ in component.list("screen") do
  screens[#screens + 1] = addr
end

update()

while true do
  local evt, from, operation, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 = recv()
  if evt and operation and from then
    if evt == "ipc" then
--      kernel.logger.log("GPU", operation, "<-", from, "=", kernel.thread.info(from).name)
      if gpu[operation] then
        ipc.send(from, gpu[operation](arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8))
      else
        ipc.send(from, "invalid operation")
      end
    elseif evt == "component_added" then
      if operation == "gpu" then
        gpus[#gpus + 1] = from
      elseif operation == "screen" then
        screens[#screens + 1] = from
      end
      update()
    elseif evt == "component_removed" then
      if operation == "gpu" then
        for i=1, #gpus, 1 do
          if gpus[i] == from then
            table.remove(gpus, i)
            break
          end
        end
      elseif operation == "screen" then
        for i=1, #screens, 1 do
          if screens[i] == from then
            table.remove(screens, i)
            break
          end
        end
      end
      update()
    end
  end
end
