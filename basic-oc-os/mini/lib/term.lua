-- A term library --

local gpu = require("gpu")

local term = {}

local cursorX, cursorY, width, height = 1, 1, gpu.getResolution()

local function hideCursor()
  gpu.set(cursorX, cursorY, " ")
end

local function showCursor()
  gpu.set(cursorX, cursorY, unicode.char(0x28FF))
end

function term.getCursorPosition()
  return cursorX, cursorY
end

function term.setCursorPosition(newX, newY)
  checkArg(1, newX, "number")
  checkArg(2, newY, "number")
  hideCursor()
  cursorX, cursorY = newX, newY
  showCursor()
end

function term.scroll(lines)
  checkArg(1, lines, "number")
  hideCursor()
  gpu.copy(1, 1, width, height, 0, 0 - lines)
  gpu.fill(1, width, height, lines, " ")
  cursorY = cursorY - lines
  showCursor()
end

function term.clear()
  gpu.fill(1, 1, width, height, " ")
  term.setCursorPosition(1, 1)
end

function term.write(toWrite)
  checkArg(1, toWrite, "string")
  hideCursor()
  for charToWrite in toWrite:gmatch(".") do
    --gpu.set(width, height, charToWrite)
    if charToWrite == "\n" or cursorX == height then -- ono, we're writing a newline
      if cursorY == height then -- we need to scroll
        term.scroll(1)
      else -- we do not need to scroll
        cursorY = cursorY + 1
      end
      cursorX = 1
    end
    if charToWrite ~= "\n" then
      gpu.set(cursorX, cursorY, (charToWrite ~= "\n" and charToWrite) or "")
      cursorX = cursorX + 1
    end
  end
  showCursor()
end

-- Fairly basic text imput function
function term.read()
  local read = ""
  local enter = 13
  local backspace = 8
  local startX, startY = term.getCursorPosition()
  local function redraw()
    term.setCursorPosition(startX, startY)
    term.write(read) --.. " ") -- the extra space ensures that chars are properly deleted
  end
  while true do
    redraw()
    local signal, _, charID, keycode = computer.pullSignal() -- signal is the signal ID, charID is the ASCII code of the pressed character, and keycode is the physical keyboard code. Note that these are keypress-specific!!
    if signal == "key_down" then -- A key has been pressed
      if charID > 31 and charID < 127 then -- If the character is printable, i.e. 0-9, a-z, A-Z, `~!@#$%^&*()_+-=[]{}\|;':",./<>?
        read = read .. string.char(charID)
      elseif charID == backspace then -- The character is backspace
        read = read:sub(1, -2) -- Remove a character from the end of our read string
      elseif charID == enter then -- my god Kate's syntax detection is crap
        read = read .. "\n"
        redraw()
        return read
      end
    end
  end
end

return term
