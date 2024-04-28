-- MKDIR --

local args = {...}

local flags, args = shell.parseArgs(args)

local ignoreErrors = false
local dirToMake

if #args < 1 then
  print("Usage: mkdir DIR")
  return
end

if #flags > 0 then
  for i=1, #flags, 1 do
    if #flags[i] >= 2 then -- We've got a long enough flag
      for n=2, #flags[i], 1 do
        local c = flags[i]:sub(n,n)
        if c == "p" then
          ignoreErrors = true
        end
      end
    end
  end
end

if not type(args[1]) == "string" then
  errors.invalidArgumentError("string", type(args[1]))
  return
end

dirToMake = shell.resolvePath(args[1])

local ok, err = pcall(function()fs.makeDir(dirToMake)end)

if not ok and not ignoreErrors then errors.error(err) end
