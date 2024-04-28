-- An elegant way of throwing errors, from a more civilized age.... --

local function baseError(msg) -- Prevent code repetition
    term.setTextColor(colors.red)
    print("-> " .. msg)
    term.setTextColor(colors.yellow)
end

local function notFound(thing)
    baseError(thing .. " not found")
end

function fileNotFound(file)
    notFound(file or "File")
end

function error(msg)
    baseError(msg)
end

function programNotFound(prg)
    notFound(program or "Program")
end

function APINotFound(api)
    notFound(((api .. " API") or "API"))
end

function accessDenied(file)
    baseError(((file .. " ") or "") .. "Access denied") -- 'Tis but a scratch!
end
