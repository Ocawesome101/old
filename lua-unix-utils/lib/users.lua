local users = {}

local uname = "root"
local uid = 0

function users.user()
  return uname
end

function users.uid()
  return uid
end

function users.login(user, password) -- Placeholder
  uname = user
  uid = math.random(1,100)
end

function users.homeDir()
  if uname ~= "root" then
    return "/home/" .. uname
  else
    return "/root"
  end
end

return users
