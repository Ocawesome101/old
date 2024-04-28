-- ls --

local args = ...

if args[1] then
    if not fs.exists(args[1]) then
        return false
    end
end

local list = {}

if not args[1] then
    list = fs.list(shell.dir())
else
    list = fs.list(args[1])
end

if settings.get("ls.printDir") == ("true" or true) then
    print(args[1] or shell.dir())
end

local files, dirs = {}, {}

local dir = (args[1] or shell.dir())

for i=1, #list, 1 do
    if fs.exists(dir .. "/" .. list[i]) and list[i]:sub(1,1) ~= "." and list[i] ~= "rom" then
        if fs.isDir(dir .. "/" .. list[i]) then
            table.insert(dirs, list[i])
        else
            table.insert(files, list[i])
        end
    end
end

textutils.pagedTabulate(colors.orange, dirs, colors.lightGray, files)

term.setTextColor(colors.white)
