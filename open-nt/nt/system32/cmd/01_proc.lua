-- Load and start the shell process --

require("ex.ps").spawn(assert(loadfile("A:/NT/System32/cmd.lua", nil, _G, {drive = "A:", cd = "/"})), "cmd.lua", print)
