-- Require --

local requirePath = "/lib/"

function require(file)
  if not fs.exists(requirePath .. file .. ".lua") then
    print("Could not find " .. file .. " under " .. requirePath)
    return nil
  end

  local ok, err = loadfile(requirePath .. file .. ".lua")

  if not ok then
    print(err)
    return nil
  end

  setfenv(ok, _G)
  return ok()
end
