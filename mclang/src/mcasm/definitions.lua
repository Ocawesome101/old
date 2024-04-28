-- Assembler instruction definitions --

local defs = {}

function defs.set(addr, val)
  return string.format("scoreboard objectives set %d oc.sys.ram %d", addr, val)
end

-- add value in a1 to value in a2
function defs.add(a1, a2)
  return string.format("scoreboard players operation %d oc.sys.ram += %d com.oc.sys", a2, a1)
end

function defs.mov(a1, a2)
  return string.format("scoreboard players set %d oc.sys.ram 0\nscoreboard players set %d oc.sys.ram a2", a2)
end

function defs.exe(...)
  return table.concat(table.pack(...))
end

function defs.bnc(pt)
  return string.format("function %s", pt)
end

function defs.beq(a1, a2, pt)
  return string.format("execute if score %d oc.sys.ram = %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.bne(a1, a2, pt)
  return string.format("execute unless score %d oc.sys.ram = %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.blt(a1, a2, pt)
  return string.format("execute if score %d oc.sys.ram < %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.ble(a1, a2, pt)
  return string.format("execute if score %d oc.sys.ram <= %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.bgt(a1, a2, pt)
  return string.format("execute if score %d oc.sys.ram > %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.bge(a1, a2, pt)
  return string.format("execute if score %d oc.sys.ram >= %d oc.sys.ram run function %s", a1, a2, pt)
end

function defs.scr(x, y, chr)
  return string.format("scoreboard players set %d oc.sys.vram %d", ((y+x//40)*40)+x-x//40, col)
end

function defs.scrupd()
  local ret = ""
  for i=1, 640, 1 do
    ret = ret .. string.format("execute if score %d oc.sys.vram matches 0\n")
  end
end

return defs
