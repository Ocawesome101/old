-- Keyboard detection --

if __screen.getKeyboards() == {} then
  io.error("No keyboard detected","panic")
else
  io.error("Found keyboard(s)","panic")
end
