-- GPU api for OC-OS. Will be used until I can get GPUs working with a proxy --

_G.gpu = {}

_G.gpu.address = __gpu -- I know, it's not an official function, but it's kinda nice to have

_G.gpu.setResolution = function(x,y)
  return __invoke(__gpu,"setResolution",x,y)
end

_G.gpu.maxResolution = function()
  return __invoke(__gpu, "maxResolution")
end

_G.gpu.bind = function(scr)
  return __invoke(__gpu,"bind",scr)
end

_G.gpu.getScreen = function()
  return __invoke(__gpu,"getScreen")
end

_G.gpu.getBackground = function()
  return __invoke(__gpu,"getBackground")
end

_G.gpu.setBackground = function(color, isIndex)
  return __invoke(__gpu,"setBackground",color,isIndex)
end

_G.gpu.getForeground = function()
  return __invoke(__gpu,"getForeground")
end

_G.gpu.setForeground = function(color,isIndex)
  return __invoke(__gpu,"setForeground",color,isIndex)
end

_G.gpu.getPaletteColor = function(index)
  return __invoke(__gpu,"getPaletteColor",index)
end

_G.gpu.setPaletteColor = function(index,value)
  return __invoke(__gpu,"setPaletteColor",index,value)
end

_G.gpu.maxDepth = function()
  return __invoke(__gpu,"maxDepth")
end

_G.gpu.getDepth = function()
  return __invoke(__gpu,"getDepth")
end

_G.gpu.setDepth = function()
  return __invoke(__gpu,"setDepth")
end

_G.gpu.getResolution = function()
  return __invoke(__gpu,"getResolution")
end

-- gpu.getViewport and setViewport are excluded. What even are they?

_G.gpu.get = function(x,y)
  return __invoke(__gpu,"get",x,y)
end

_G.gpu.set = function(x,y,str,vert)
  return __invoke(__gpu,"set",x,y,str,vert)
end

_G.gpu.copy = function(x,y,w,h,tx,ty)
  return __invoke(__gpu,"copy",x,y,w,h,tx,ty)
end

_G.gpu.fill = function(x,y,w,h,char)
  return __invoke(__gpu,"fill",x,y,w,h,char)
end
