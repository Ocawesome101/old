-- Net API - hostname, HTTP wrapper --

setHostname = os.setComputerLabel

hostname = os.getComputerLabel


function get(url, file)
    if http.checkURL(url) then
        local h = http.get(url)
        local data = h.readAll()
        h.close()
        if file then
            local h = fs.open(file, "w")
            h.write(data)
            h.close()
            return true
        else
            return data
        end
    else
        errors.httpNotFound()
        return false
    end
end
