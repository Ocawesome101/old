-- init --

prox = component.proxy computer.getBootAddress!

export loadfile = (file) ->
  handle = assert prox.open file, "r"
  data = ""
  while true
    chunk = prox.read handle, math.huge
    break unless chunk
    data ..= chunk
  prox.close handle
  load data, "="..file, "bt", _G

x = assert loadfile "/stream/core.lua"

x!
