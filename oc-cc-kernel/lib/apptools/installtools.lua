-- Install Tools --

local errors = require("liberrors")

local inst = {}

function inst.getPerms(pkgPath)
  if not fs.exists(pkgPath .. "/install.cfg") then
    errors.missingRequiredFileError(pkgPath .. "/install.cfg")
    return false
  end

  local inst_cfg = dofile(pkgPath .. "/install.cfg")
end
