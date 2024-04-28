-- Rudimentary task scheduler --

local mt = {}
local eventData = {}
mt.pstree = {}

function mt.psinit(file, ...)
  local ok, err = loadfile(file)
  if not ok then
    error(err)
  end

  local crt = coroutine.create(ok, ...)
  local pid = #mt.pstree + 1
  
  table.insert(mt.pstree,{ps = crt})

  return pid
end

function mt.psupdate()
  for i=1, #mt.pstree, 1 do
    coroutine.resume(mt.pstree[i].ps)
  end
end

function mt.pskill(pid)
  table.remove(mt.pstree, pid)
end

return mt
