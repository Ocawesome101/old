-- Initialize the rest of the system. We should now have a usable base to work with,
-- since /sys/boot.lua did much of the initializing. This is more of a module-loader
-- than an actual initializer. --

local modpath = "/sys/core/boot_modules/"

local modules = fs.list(modpath)

if modules == nil then
  print("No modules to load")
  return
end

for i=1, #modules, 1 do
  print("Loading module " .. modules[i])
  os.run(modpath .. modules[i])({})
end
