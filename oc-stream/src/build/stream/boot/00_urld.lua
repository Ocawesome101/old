urld = { }
local protocols = { }
urld.resolve = function(url)
	checkArg(1, url, "string")
	local proto, domain, qstr = url:match("(.-)://(.-)(%?.+)")
	if not protocols[proto] then
		return nil, "no such protocol"
	end
	return protocols[proto]:resolve(domain, qstr)
end
urld.addproto = function(proto, ent)
	checkArg(1, proto, "string")
	checkArg(2, ent, "table")
	if protocols[proto] then
		return nil, "protocol entry already specified"
	end
	if not ent.resolve then
		return nil, "invalid protocol entry"
	end
	protocols[proto] = ent
end
