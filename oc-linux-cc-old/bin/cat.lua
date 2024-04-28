-- You can tell what I pulled from CraftOS and what I made, can't you? --
local args = {...}

if #args < 1 then
 printError('Usage: cat <file>')
 return
end 

local file = (args[1])
local cfile = shell.resolve(file)

if not fs.exists(cfile) then
 printError('cat: '..file..': No such file or directory')
 return
end

if fs.isDir(cfile) then
 printError('cat: '..file..': Is a directory')
 return
end

local catfile = fs.open(cfile, 'r')
local cf = catfile.readAll()
catfile.close()
print(cf)

