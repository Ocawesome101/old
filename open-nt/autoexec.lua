-- This file will be automatically executed at boot if it exists.

io.write("\n")

local conf = require("ntconfig")

if conf.services then
  print("Starting services...\n")
  require("svc").start("automnt")
end
