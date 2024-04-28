-- The shell API. Not the shell itself, but just the API. --

_G.shell = {}

print("Initializing shell API")

shell.run = function(program, args)
  if type(args) ~= "table" then
    io.error("shell.run: args must be a table")
    return false
  else
    os.run(program)(args)
  end
end

shell.prompt = {"user","@","hostname","dir"," :"}

shell.parsePrompt = function(prompt)
  if not prompt then prompt = shell.prompt end

  local rtn = ""

  for i=1, #prompt, 1 do
    if prompt[i] == "user" then
      if _G.__USER then
        rtn = rtn .. _G.__USER
      end
   elseif prompt[i] == "hostname" then
   

end
