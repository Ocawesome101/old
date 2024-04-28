local mmap = { }
local smodem = nil
do
	local maddr
	local _obj_0 = (component.list("modem"))
	if _obj_0 ~= nil then
		maddr = _obj_0()
	end
	if not maddr then
		return
	end
	smodem = function()
		return component.proxy(function(addr) end)
	end
end
local open
open = function(pid) end
local listener
listener = function()
	while true do
		local sig = table.pack(coroutine.yield())
		if sig[1] == "modem_message" then
			if sig[4] == 42 then
				if ops[sig[6]] then
					ops[sig[6]](table.unpack(sig, 3))
				end
			end
		elseif sig[1] == sched.IPCOPEN then
			coroutine.yield(stream.new(open(sig[3])))
		end
	end
end
local proto = {
	resolve = function(domain, query) end
}
return urld.add("snet", proto)
