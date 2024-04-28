-- FS API. Very simple for the moment. --

_G.__mounts = {}

_G.__rootfs = ""

_G.fs = component.proxy(computer.getBootAddress()) --Most of the API

fs.mount = function(addr,path)
  if __rootfs == "" and not path == "/" then
    error("You must mount the root filesystem first")
  end
  if path == "/" then
    __rootfs = addr
  end
  table.insert(__mounts,{addr,path})
end
