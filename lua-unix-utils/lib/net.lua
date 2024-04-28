-- Simple networking wrapper --

local net = {}

function net.hostname()
  if (not os.getComputerLabel()) or (os.getComputerLabel() == "") then
    return "localhost"
  else
    return os.getComputerLabel()
  end
end

return net
