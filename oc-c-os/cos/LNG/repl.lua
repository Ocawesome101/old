-- Lua REPL --

local mod = {}

local PWD = computer.getBootAddress():sub(1,3) .. ":/"
function pwd(v)
  checkArg(1, v, "string", "nil")
  if v then
    if not v:find(":") then
      v = computer.getBootAddress():sub(1,3)..":"..v
    end
    local node, err = sys.resolve(v)
    if not node or not node.exists(err) or not node.isDirectory(err) then
      return nil, "no such directory"
    end
    PWD = v
  end
  return PWD
end

function clist(typ)
  checkArg(1, typ, "string", "nil")
  for ad, typ in component.list(typ) do
    printf("%36s: %s\n", ad, typ)
  end
end

function ps()
  local thd = sys.threads()
  for k, v in pairs(thd) do
    printf("%4x  %s\n", k, v)
  end
end

function kill(pid)
  return sys.kill(pid)
end

function free()
  print("%dKB total, %dKB used, %dKB free", computer.totalMemory() // 1024, (computer.totalMemory() - computer.freeMemory()) // 1024, computer.freeMemory() // 1024)
end

function fcat(...)
  local files = table.pack(...)
  for i=1, files.n, 1 do
    local node, path = sys.resolve(files[i] or "OWZ:/") -- random thingy
    if not node then
      return nil, path
    end
    local fd, err = node.open(path, "r")
    if not fd then
      return nil, err
    end
    repeat
      local chunk = node.read(fd, math.huge)
      if chunk then printf("%s", chunk) end
    until not chunk
   node.close(fd)
  end
end

cget = component.get
cpx = component.proxy

function list(dir)
  checkArg(1, dir, "string", "nil")
  dir = dir or pwd()
  local node, path = sys.resolve(dir)
  if not node then
    return nil, path
  end
  local files = node.list(path)
  for i=1, #files, 1 do
    printf("%s\n", files[i])
  end
end

local function repl()
  term.clear()
  while true do
    printf("%s>", pwd())
    local inp = term.read()
    local ok, err = load("return "..inp, "=stdin")
    if not ok then
      ok, err = load(inp, "=stdin")
    end
    if not ok then
      print("%s\n", err)
    end
    local rst = table.pack(pcall(ok))
    if not rst[1] then
      print("%s\n", rst[2])
    else
      for i=2, rst.n, 1 do
        print("%s", tostring(rst[i]))
      end
    end
  end
end

function mod.load()
  sys.spawn(repl, "C/OS REPL")
end

-- XXX IMPORTANT XXX
-- A mod.unload definition is *not* provided. This
-- is intentional.

return mod
