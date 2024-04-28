-- Very basic shell --

print("Welcome to the CC-BIOS debug shell")

local function display(obj)
    if type(obj) == "table" then
        for i=1, #obj, 1 do
            display(obj[i])
        end
    else
        print(obj)
    end
end

function ls(dir)
    local files = fs.list(dir)
    for i=1, #files, 1 do
        print(files[i])
    end
end

while true do
    write("> ")
    local s, data = pcall(loadstring(read()))
    if data then
        display(data)
    end
end
