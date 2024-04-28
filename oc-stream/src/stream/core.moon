-- core: scheduler and streams, and that's it --

-- thread: coroutine API wrapper
do
  global thread = {}
  mt =
    __metatable: {}
    __index: thread

  thread.create = (func) ->
    checkArg 1, func, "function"
    new =
      __coro: coroutine.create func
    setmetatable new, mt
    new

  thread.wrap = (func) ->
    checkArg 1, func, "function"
    new = thread.create func
    (...) ->
      new\resume ...

  thread.resume = (...) => coroutine.resume self.__coro, ...
  thread.status = () => coroutine.status self.__coro
  thread.isyieldable = () => coroutine.isyieldable(self)

-- streams
do
  st = {}
  st.read = (n) =>
    if self.internal.read
      self.internal.read n
    else
      while #self.buf < n
        coroutine.yield!
      ret = self.buf\sub 1, n
      self.buf = self.buf\sub n+1
      ret

  st.write = (dat) =>
    if self.internal.write
      self.internal.write dat
    else
      self.buf ..= dat
    true
  
  st.close = =>
    if self.internal.close
      self.internal.close!
    self.closed = true
    true

  mt =
    __index: st

  global stream = (rint={}, wint={}) ->
    rs =
      buf: ""
      internal: rint
    ws =
      buf: ""
      internal: wint

    rs, ws

-- scheduler
do
  s = {}
  global sched = s
  s.IPCOPEN = 127
  last = 0
  threads = {}
  ppid = (pid) ->
    node, sg, id = pid\match("(%d+)%.(%d+)%.(%d+)")
    tonumber(node), tonumber(sg), tonumber(id)

  s.spawn = (func, group=2) ->
    checkArg 1, func, "function"
    checkArg 2, group, "number"
    lastID += 1
    new =
      thd: thread.create func
      pid: string.format "0.%d.%d", sg, lastID
    threads[new.pid] = new
    new.pid
  
  s.open = (pid) ->
    checkArg 1, pid, "string"
    node, sg, id = ppid pid
    if node == 0
      return coroutine.yield s.IPCOPEN, pid
    else
      return nil, "cannot open external process (use urld.resolve instead)"

  import pullSignal from computer
  s.loop = ->
    s.loop = nil
    ipcbuf = {}
    while #threads > 0
      sig = table.pack pullSignal
      for k,v in pairs ipcbuf
        if #v > 0
          rq = table.remove v, 1
          ipcbuf[rq.pid] = table.pack threads[k].thd\resume table.unpack rq
          table.remove ipcbuf[rq.pid], 1
          if threads[k].thd\status == "dead"
            threads[k] = nil

      for k, v in pairs threads
        ret = table.pack v.thd\resume sig
        if ret[2] == sched.IPCOPEN
          ipcbuf[ret[3]] or= {}
          table.insert ipcbuf[pid], table.pack table.unpack ret, 2
        if v.thd\status! == "dead"
          threads[k] = nil

-- load and execute everything from /stream/boot/
do
  global fs = component.proxy computer.getBootAddress!
  files = fs.list "/stream/boot"
  table.sort files
  for _, file in pairs files
    (assert loadfile file)!

sched.loop!
