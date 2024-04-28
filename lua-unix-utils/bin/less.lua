-- Less --

local args = {...}

local function draw(tLines, start)
    if not tLines[start] then
        error("Value 'start' out of range")
        return false
    end
    
    local w,h = term.getSize()
    
    h = h - 1
    term.setCursorPos(1,1)
    
    local stop
    
    if #tLines > h then
        stop = h
    else
        stop = #tLines
    end
    
    for i=start, h+(start-1), 1 do
        term.clearLine()
        print((tLines[i] or ""))
    end
end

local function drawCtrl()
    local w,h = term.getSize()
    term.setCursorPos(1, h)
    
    term.clearLine()
    write(":")
end

local function redraw(l, st)
    draw(l, st)
    drawCtrl()
end

local function getLines(handle)
    local rtn = {}
    for line in handle:lines() do
        table.insert(rtn, line)
    end
    
    return rtn
end

local function createIterable(t)
    local i = 1
    local rtn = function()
        local x = t[i]
        i = i + 1
        return x 
    end
end

local baseFuncs = {
    openFile = function(file)
        return io.open(shell.resolve(file))
    end
}

if #args < 1 then
    error("Must specify file name")
    return false
end

if not fs.exists(shell.resolve(args[1])) then
    error(shell.resolve(args[1]) .. " does not exist")
    return false
end

local h = baseFuncs.openFile(args[1])

local lines = getLines(h)

h:close()

top = 1

redraw(lines, top)
local w,h = term.getSize()
term.setCursorPos(1, h)
term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
write(args[1])
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

sleep(0.1)
while true do
    local tEvent = {os.pullEvent()}
    local w,h = term.getSize()
    if tEvent[1] == "key" and tEvent[2] == keys.down then
        if top + h < #lines+2 then
            top = top + 1
        end
    elseif tEvent[1] == "key" and tEvent[2] == keys.up then
        if top > 1 then
            top = top - 1
        end
    elseif tEvent[1] == "key" and tEvent[2] == keys.q then
        term.setCursorPos(1,1)
        term.clear()
        sleep(0.1)
        break
    end
    redraw(lines, top)
end
