-- sl --

local phrase = "slow.Locomotive"

local x, y = term.getCursorPos()

local w, h = term.getSize()

if y + 9 > h then
    repeat
        y = y - 1
    until y + 9 == h 
end

local i = phrase:len()

repeat
    term.setCursorPos(1, y)
    for n=1, 9, 1 do
        print(phrase:sub(i))
    end
    sleep(0.01)
    i = i - 1
until i == 0
