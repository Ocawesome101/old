-- STREAMNET support --

mmap = {}
smodem = nil
do
  maddr = (component.list "modem")?!
  unless maddr return
  smodem = component.proxy maddr

smodem.open 42

open = (pid) ->
  smodem.

listener = ->
  while true
    sig = table.pack coroutine.yield!
    if sig[1] == "modem_message"
      if sig[4] == 42
        if ops[sig[6]]
          ops[sig[6]] table.unpack sig, 3

proto =
  resolve: (pid, query) ->
    

pidpr =
  resolve: (pid, query) ->
    node, group, id = ppid pid
    if node == 0
      return s.open pid
    else
      return proto.resolve pid, query

urld.add("snet", proto)
urld.add("pid", pidpr)
