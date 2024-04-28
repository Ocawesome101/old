do
	thread = { }
	local mt = {
		__metatable = { },
		__index = thread
	}
	thread.create = function(func)
		checkArg(1, func, "function")
		local new = {
			__coro = coroutine.create(func)
		}
		setmetatable(new, mt)
		return new
	end
	thread.wrap = function(func)
		checkArg(1, func, "function")
		local new = thread.create(func)
		return function(...)
			return new:resume(...)
		end
	end
	thread.resume = function(self, ...)
		return coroutine.resume(self.__coro, ...)
	end
	thread.status = function(self, )
		return coroutine.status(self.__coro)
	end
	thread.isyieldable = function(self, )
		return coroutine.isyieldable(self)
	end
end
do
	local st = { }
	st.read = function(self, n)
		if self.internal.read then
			return self.internal.read(n)
		else
			while #self.buf < n do
				coroutine.yield()
			end
			local ret = self.buf:sub(1, n)
			self.buf = self.buf:sub(n + 1)
			return ret
		end
	end
	st.write = function(self, dat)
		if self.internal.write then
			self.internal.write(dat)
		else
			self.buf = self.buf .. dat
		end
		return true
	end
	st.close = function(self)
		if self.internal.close then
			self.internal.close()
		end
		self.closed = true
		return true
	end
	local mt = {
		__index = st
	}
	stream = function(rint, wint)
		if rint == nil then
			rint = { }
		end
		if wint == nil then
			wint = { }
		end
		local rs = {
			buf = "",
			internal = rint
		}
		local ws = {
			buf = "",
			internal = wint
		}
		return rs, ws
	end
end
do
	local s = { }
	sched = s
	s.IPCOPEN = 127
	local last = 0
	local threads = { }
	local ppid
	ppid = function(pid)
		local node, sg, id = pid:match("(%d+)%.(%d+)%.(%d+)")
		return tonumber(node), tonumber(sg), tonumber(id)
	end
	s.spawn = function(func, group)
		if group == nil then
			group = 2
		end
		checkArg(1, func, "function")
		checkArg(2, group, "number")
		lastID = lastID + 1
		local new = {
			thd = thread.create(func),
			pid = string.format("0.%d.%d", sg, lastID)
		}
		threads[new.pid] = new
		return new.pid
	end
	s.open = function(pid)
		checkArg(1, pid, "string")
		local node, group, id = ppid(pid)
		return coroutine.yield(sched.IPCOPEN, pid)
	end
	local pullSignal = computer.pullSignal
	s.loop = function()
		s.loop = nil
		local ipcbuf = { }
		while #threads > 0 do
			local sig = table.pack(pullSignal)
			for k, v in pairs(ipcbuf) do
				if #v > 0 then
					local rq = table.remove(v, 1)
					ipcbuf[rq.pid] = table.pack(threads[k].thd:resume(table.unpack(rq)))
					table.remove(ipcbuf[rq.pid], 1)
					if (function()
						local _base_0 = threads[k].thd
						local _fn_0 = _base_0.status
						return _fn_0 and function(...)
							return _fn_0(_base_0, ...)
						end
					end)() == "dead" then
						threads[k] = nil
					end
				end
			end
			for k, v in pairs(threads) do
				local ret = table.pack(v.thd:resume(sig))
				if ret[2] == sched.IPCOPEN then
					local _update_0 = ret[3]
					ipcbuf[_update_0] = ipcbuf[_update_0] or { }
					table.insert(ipcbuf[pid], table.pack(table.unpack(ret, 2)))
				end
				if v.thd:status() == "dead" then
					threads[k] = nil
				end
			end
		end
	end
end
do
	fs = component.proxy(computer.getBootAddress())
	local files = fs.list("/stream/boot")
	table.sort(files)
	for _, file in pairs(files) do
		(assert(loadfile(file)))()
	end
end
return sched.loop()
