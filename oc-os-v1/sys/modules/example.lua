-- Kernel module / API example --

local e = function()
    log("Example", "example")
end

_G.example = e 

return nil
