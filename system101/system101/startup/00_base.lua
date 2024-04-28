
local status = ...
local filesystem = require("filesystem")

status(">> (1/2) loading process...")
--local process = require("process")

status(">> (2/2) starting servers...")
for _, file in pairs(filesystem.list("/system101/servers")) do
  error("AAA")
  process.load("/system101/servers/"..file)
end
