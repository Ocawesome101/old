-- A simple shell. Actually just a Lua interpreter. --

_G.term = require("term")
_G.gpu = require("gpu") -- This is where the loaded = { ["gpu"] = gpu } line comes in
term.clear()

function _G.print(...)
  local args = {...}
  for k, v in pairs(args) do
    term.write(tostring(v) .. " ")
  end
  term.write("\n")
end

local currentDirectory = "/" -- self explanatory

local function drawPrompt()
  gpu.setForeground(0x00FF00) -- Colors are stored as 24-bit hexadecimal values. (Look up "hexadecimal color"). 0x00FF00 is bright green.
  term.write("\n" .. currentDirectory .. " > ")
  gpu.setForeground(0xFFFFFF)
end

local function printError(err)
  gpu.setForeground(0xFF0000)
  term.write(err .. "\n")
  gpu.setForeground(0xFFFFFF)
end

local function execute(command)
  local ok, err = load(command, "=lua")
  if not ok then
    ok, err = load("=" .. command, "=lua")
    if not ok then
      return nil, err
    end
  end
  local result = {pcall(ok)} -- pcall, or protected call, captures errors. Very useful function.
  if not result[1] and result[2] then
    return printError(result[2])
  end
  for i=#result, 1, -1 do
    print(result[i])
  end
end

while true do
  drawPrompt()
  local command = term.read()
  if command ~= "\n" then
    execute(command)
  end
  computer.pullSignal()
end
