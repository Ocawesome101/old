-- package, dofile, and require --

_G.package = {}

package.loaded = {
  _G        = _G,
  os        = os,
  unicode   = unicode,
  coroutine = coroutine,
  computer  = computer,
  string    = string,
  package   = package,
  math      = math,
  table     = table,
  debug     = debug
}

_G.component, _G.computer, _G.unicode = nil, nil, nil

package.path = "/l4/?.lua;/l4/?/init.lua;/l4/?/?.lua;/share/?.lua;/share/?/init.lua;/share/?/?.lua"

local function genLibError(_path, name)
  local err = "module '%s' not found:\n\tNo field package.loaded['%s']"
  local paths = {}
  for path in _path:gmatch("[^;]+") do
    err = err .. "\n\tNo file '%s'"
    path = path:gsub("%?", name)
    paths[#paths + 1] = path
  end
  return err:format(name, name, table.unpack(paths))
end

function package.searchpath(name, path, sep, rep)
  checkArg(1, name, "string")
  checkArg(2, path, "string")
  checkArg(3, sep, "string", "nil")
  checkArg(4, rep, "string", "nil")
  local sep = sep or "."
  local rep = rep or "/"
  local name = name:gsub('%'..sep, rep)
  for _path in path:gmatch("[^;]+") do
    _path = _path:gsub("%?", name)
    --local rst = {}
    if _path:sub(1,1) ~= "/" and os.getenv then
      _path = ipcsend("drv/filesystem", "concat", (os.getenv("PWD") or "/"), _path)
    end
    if ipcsend("drv/filesystem", "exists", _path) then
      return _path
    end

    --[[kernel.log(tostring(rst[1]), tostring(rst[2]))
    if rst[1] then
      return _path
    end]]
  end
  return nil, genLibError(path, name)
end

function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  --local rst = {}
  local fs, err = ipcopen("drv/filesystem")
  if not fs then
    return nil, "failed opening filesystem server channel: " .. err
  end
  local handle, err = fs:write("open", file)
  --[[if not rst[1] then
    return nil, rst[2]
  end]]
  local tmp = handle:readAll()
  handle:close()
  fs:close()
  return load(tmp, "=" .. file, mode or "bt", env or _G)
end

function _G.dofile(file)
  checkArg(1, file, "string")
  local ok, err = loadfile(file)
  if not ok then
    return nil, err
  end
  local s, r = pcall(ok)
  if s then
    return r
  else
    return nil, r
  end
end

function _G.require(module)
  checkArg(1, module, "string")
  if package.loaded[module] ~= nil then
    return package.loaded[module]
  else
    local mpath, err = package.searchpath(module, package.path)
    if not mpath then
      error(err)
    end
    local ok, err = dofile(mpath)
    if not ok then
      error(err)
    end
    package.loaded[module] = ok
    return ok
  end
end
