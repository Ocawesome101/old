-- Users API for OC-OS. Very similar in both functionality and design to the ComputerCraft version. In fact, mostly copy-and-pasted --

local username = "root"
local userid = 0

local root_password = "root" -- Shhhh, don't tell anyone!

_G.users = {}

function users.user()
    return username
end

function users.uid()
    return userid
end

function users.login(u, p)
    local function x(file)
        local handle = fs.open("/sys/userdata/" .. file, "r")
        if not handle then
            return nil
        end

        local data = {}

        while true do
            local line = handle:readLine()
            if line and line ~= "" then
                table.insert(data,line)
            else
                break
            end
        end
        handle.close()
        return data
    end

    local names = x("names")
    local passwords = x("passwords")

    for i=1, #names, 1 do
        if names[i] == u then
            if passwords[i] == p then
                username = u
                userid = i
                return true -- Success! We're logged in.
            else
                errors.error("Invalid password")
                return false -- Better luck next time.
            end
        end
    end
    if u == "root" and p == root_password then
        username = "root"
        userid = 0
        return true
    end
end

function users.logout()
    username = ""
    userid = -1
end

function users.homeDir(u)
    return "/users/" .. u .. "/"
end
