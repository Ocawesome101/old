-- keyboard --

local pressed = {}

local c = 0x2E
local d = 0x20
local e = 18
local lctrl = 0x1D
local rctrl = 0x9D
local right = 205
local left = 203

while true do
  local e, _, id, code = recv()
  if e == "key_down" then
    pressed[code] = true
    if pressed[lctrl] or pressed[rctrl] then
      if pressed[c] then
        push("interrupt")
      elseif pressed[d] then
        push("exit")
      end
    end
  elseif e == "key_up" then
    pressed[code] = nil
  end
end
