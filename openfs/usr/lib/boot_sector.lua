local a,i,l,s,e,d,o,E,S,g=computer.getBootAddress(),component.invoke,component.list,2,24,""
g,S=l("gpu")(),l("screen")()
if g and S then i(g,"bind",S)i(g,"set",1,1,"Loading bootloader")end
for _i=s,e do d=d..i(a,"readSector",_i)end
o,E=load(d,"=bootloader","bt",_G)if not o then error(E)end
o()--[[This boot sector is part of the OpenBootLoader project.
See https://github.com/Ocawesome101/OpenBootLoader for details.
Feel free to contribute, particularly towards the OpenFS drivers or OpenBootLoader!]]
