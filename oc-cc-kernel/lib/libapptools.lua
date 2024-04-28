-- Various tools related to applications --

local apptools = {}
local errors = require("liberrors")
local sandbox = require("security/sandbox")
local installTools = require("apptools/installtools")

function apptools.run(has, app, ...)
  local sandboxedMetatable = sandbox.setupSandbox(has)
  sandbox.runWithSandbox(sandboxedMetatable, app, ...)
end

function apptools.installApp(pkg) -- App packages are just folders
  local pkgInfo = installTools.getInfo(pkg)
  local perms = pkgInfo.permissions
  local grantedPerms = {hasOS=false, hasFS=false, hasFenv=false}
  if perms.wantsFS then
    write("Allow package at " .. pkg .. " to access the filesystem? [y/N]: ")
    local a = read()
    if a:lower() == "y" then
      grantedPerms.hasFS = true
    else
      print("Disallowing filesystem access")
    end
  end
  if perms.wantsOS then
    write("Allow package at " .. pkg .. " to access the OS API? [y\N]: ")
    local a = read()
    if a:lower() == "y" then
      grantedPerms.hasOS = true
    else
      print("Disallowing OS access")
    end
  end
  if perms.wantsFenv then
    write("Allow package at " .. pkg .. " to use setfenv/getfenv? [y/N]: ")
    local a = read()
    if a:lower() == "y" then
      grantedPerms.hasFenv = true
    else
      print("Disallowing fenv usage")
    end
  end
end
