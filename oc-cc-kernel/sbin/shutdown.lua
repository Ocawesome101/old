-- Shutdown --

local args = {...}

if args[1] == "-r" then
  kernel.shutdown("reboot")
elseif args[1] == "-s" then
  kernel.shutdown()
else
  print("Usage: shutdown -r|-s")
end
