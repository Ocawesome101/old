-- An elegant way of throwing errors, from a more civilized age.... --
-- Nearly identical to the CraftOS version --

_G.errors = {}

local function baseError(msg) -- Prevent code repetition
    print("-> " .. msg)
end

local function notFound(thing)
    baseError(thing .. " not found")
end

function errors.fileNotFound(file)
    notFound(file or "File")
end

function errors.error(msg)
    baseError(msg)
end

function errors.programNotFound(prg)
    notFound(program or "Program")
end

function errors.APINotFound(api)
    notFound(((api .. " API") or "API"))
end

function errors.accessDenied(file)
    baseError(((file .. " ") or "") .. "Access denied") -- 'Tis but a scratch!
end
 
