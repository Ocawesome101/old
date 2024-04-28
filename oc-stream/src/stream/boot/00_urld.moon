-- URL resolution --

global urld = {}
protocols = {}

urld.resolve = (url) ->
  checkArg 1, url, "string"
  proto, domain, qstr = url\match "(.-)://(.-)(%?.+)"
  unless protocols[proto]
    return nil, "no such protocol"
  protocols[proto]\resolve domain, qstr

urld.addproto = (proto, ent) ->
  checkArg 1, proto, "string"
  checkArg 2, ent, "table"
  if protocols[proto] then return nil, "protocol entry already specified"
  unless ent.resolve return nil, "invalid protocol entry"
  protocols[proto] = ent
