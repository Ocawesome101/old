local args, opts = shell.parse(...)

local total = computer.totalMemory()
local free = computer.freeMemory()
local used = total - free

if opts.h then
  total = total // 1024
  free = free // 1024
  used = used // 1024
  print(string.format("Total: %dk\nUsed:  %dk\nFree:  %dk", total, used, free))
else
  print(string.format("Total: %d\nUsed:  %d\n: Free:  %d", total, used, free))
end