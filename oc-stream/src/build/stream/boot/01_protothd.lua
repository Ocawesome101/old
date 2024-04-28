local proto = {
	resolve = function(proc, query)
		return sched.open(proc)
	end
}
return urld.add("pid", proto)
