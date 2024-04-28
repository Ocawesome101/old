-- init.lua --

-- This operating system is not intended to have many features, but more so to teach new programmers. I will try to keep my code well-organized and well-commented, but no guarantees!
-- If you're new to Lua, go read the PIL (https://lua.org/pil/1.html), and keep the Lua reference manual (https://lua.org/manual/5.3/manual.html) open in case you need to reference it. (I also recommend having the OpenComputers wiki [https://ocdoc.cil.li] open.)
--  Note that the component, unicode, and computer APIs, plus checkArg, are unique to OpenComputers, and that io and package (plus require, loadfile, and dofile) must be defined by the user.
-- This OS is structured in a way that is meant to be easy-to-follow, though you can lay your own out however you like.

-- The path to our kernel. Note that it is advisable to use the 'local' keyword in front of your variables unless you want them to be accessible from everywhere.
local KERNEL_PATH = "/mini/kern.lua"

-- Get the computer's boot address
local address = computer.getBootAddress()

-- Open the kernel file for reading
local handle, err = component.invoke(address, "open", KERNEL_PATH)
if not handle then -- The kernel is probably not present!
  error(err)
end

-- Read all the data from the kernel file
local kernelData = ""
repeat
  local chunk = component.invoke(address, "read", handle, math.huge)
  kernelData = kernelData .. (chunk or "") -- (chunk or "") protects against errors
until not chunk -- End Of File

-- Close the kernel file handle
component.invoke(address, "close", handle)

-- Try to turn the data we read into a function we can call
local ok, err = load(
  kernelData,         -- the data (or "chunk")
  "=" .. KERNEL_PATH, -- what name to use for the loaded chunk, prefixed with an "="
  "bt",               -- the mode with which to load the chunk. "bt" should be generally fine
  _G
)

if not ok then -- There was probably a syntax error or some such thing
  error(err)
end

ok() -- Execute the kernel

-- an idle loop in case the kernel exits. Could be replaced with computer.shutdown()
while true do
  computer.pullSignal()
end
