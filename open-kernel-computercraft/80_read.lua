-- Do you read me? --

local cursor = " "

local acceptedChars = {}
for i=32, 126, 1 do
  acceptedChars[string.char(i)] = true
end

-- @arg @replace: Character with which to replace every character in the entered string.
-- @arg @history: Table of history
function read(replace, history)
  local str = ""
  local history = history or {""}
  local histPos = #history
  local x,y = term.getCursorPos()
  local w,h = term.getSize()
  local function redraw(c)
    term.setCursorPos(x,y)
    term.write((" "):rep(w - x))
    term.setCursorPos(x,y)
    if replace then
      term.write(replace:rep(#str))
    else
      term.write(str)
    end
    -- Simulate a cursor since the term API is apparently not capable of doing so
    local oldColor = term.getBackgroundColor()
    term.setBackgroundColor(colors.white)
    term.write(c)
    term.setBackgroundColor(oldColor)
  end
  while true do
    redraw(cursor)
    local event, id = computer.pullSignal()
    if event == "key" then
      if id == 14 then -- Backspace
        str = str:sub(1,#str-1)
      elseif id == 28 then -- Enter
        redraw("") -- No cursor
        term.setCursorPos(1,y+1)
        return str
      elseif id == 208 then -- Down arrow
        if histPos < #history then
          histPos = histPos + 1
          str = history[histPos]
        end
      elseif id == 200 then -- Up arrow
        if histPos > 1 then
          histPos = histPos - 1
          str = history[histPos]
        end
      end
    elseif event == "char" then
      str = str .. (id or "")
    end
  end
end
