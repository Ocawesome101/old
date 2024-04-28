-- packaaaaaage --

local filesystem = filesystem

local package = {}
local loaded = {
  os = os,
  math = math,
  table = table,
  bit32 = bit32,
  string = string,
  unicode = unicode,
  computer = computer,
  component = component,
  coroutine = coroutine,
  filesystem = filesystem
}

package.loaded = loaded

package.path = "/system101/lib/?.lua;/user/lib/?.lua"

function package.searchpath(name, path, sep, rep)
  checkArg(1, name, "string")
  checkArg(2, path, "string")
  sep = sep or '.'
  rep = rep or '/'
  sep, rep = '%' .. sep, rep
  name = name:gsub(sep, rep)
  local failed = {}
  for try in path:gmatch("[^;]+") do
    try = try:gsub("%?", name)
    if filesystem.stat(try) then
      local file = filesystem.open(try, "r")
      if file then
        file:close()
        return try
      end
    end
    table.insert(failed, "\tno file '" .. try .. "'")
  end
  return nil, table.concat(failed, "\n")
end

-- yes, this is taken from OpenOS
function require(module)
  checkArg(1, module, "string")
  if loaded[module] ~= nil then
    return loaded[module]
  else
    local library, status, step

    step, library, status = "not found", package.searchpath(module, package.path)

    if library then
      step, library, status = "loadfile failed", loadfile(library)
    end

    if library then
      step, library, status = "load failed", pcall(library, module)
    end

    assert(library, string.format("module '%s' %s:\n%s", module, step, status))
    loaded[module] = status
    return status
  end
end

return package
