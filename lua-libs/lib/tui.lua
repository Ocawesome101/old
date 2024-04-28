-- tui --

local term = require("lib.term")

local tui = {}

local function pad(s, w)
  return s .. (" "):rep(w - #s)
end

local function fill(tx, ty, w, h, c)
  local ln = term.color(pad(" ", w), nil, c or term.colors.bg.bright.white)
  for y=ty, ty+h, 1 do
    term.cursor(tx, y)
    io.write(ln)
  end
end

local w, h = term.getSize()
local function draw(items, title, hlt, sel)
  fill(2, 2, w - 4, h - 4)
  term.cursor(3, 3)
  io.write(term.color(title, term.colors.fg.black, term.colors.bg.bright.white))
  for i=1, #items, 1 do
    local text = pad(items[i].text, w - 10)
    if items[i].selectable then
      if sel[i] then
        text = "[x] " .. text
      else
        text = "[ ] " .. text
      end
    else
      text = "--> " .. text
    end
    if hlt == i then
      text = term.color(text, term.colors.fg.bright.white, term.colors.bg.red)
    else
      text = term.color(text, term.colors.fg.black, term.colors.bg.bright.white)
    end
    term.cursor(3, i + 4)
    io.write(text)
  end
end

function tui.menu(items, title)
  io.write(term.color("", nil, term.colors.bg.blue))
  term.clear()
  title = title or "Menu"
  local sel = 1
  local selected = {}
  while true do
    draw(items, title, sel, selected)
    local key = term.getKey()
    if key == "up" then
      if sel > 1 then sel = sel - 1 end
    elseif key == "down" then
      if sel < #items then sel = sel + 1 end
    elseif key == " " or key == "\13" then
      if items[sel].selectable then
        selected[sel] = not selected[sel]
      else
        selected[sel] = true
        return selected
      end
    elseif key == "left" or key == "right" then
      return selected
    end
  end
end

function tui.menuAdvanced(tstruct)
  assert(type(tstruct) == "table", "bad argument #1 (table expected)")
  local function init(t)
    local r = {}
    for k, v in pairs(t) do
      if type(v) == "table" then
        r[k] = {
          text = v.text,
          items = init(v.items),
          parent = r
        }
      else
        r[k] = {
          text = v,
          selected = false
        }
      end
    end
    return r
  end
  local struct = init(tstruct)
  local cur = {items = struct}
  fill(1, 1, w, h, term.colors.bg.blue)
  local sel = 1
  local function draw()
    fill(3, 3, w - 4, h - 4)
    local it = cur.items
    for i=1, #it, 1 do
      local text = it[i].text
      if it[i].selected then
        text = "[*] " .. text
      elseif it[i].items then
        text = "--> " .. text
      else
        text = "[ ] " .. text
      end
      if sel == i then
        text = term.color(text, term.colors.fg.bright.white, term.colors.bg.red)
      else
        text = term.color(text, term.colors.bg.white, term.colors.fg.black)
      end
      term.cursor(5, i + 5)
      io.write(text)
    end
    term.cursor(5, h)
    io.write(term.color("^/v navigate | -> enter submenu | <- exit submenu | <enter> select", term.colors.fg.bright.white, term.colors.bg.blue))
  end
  while true do
    draw()
    local key = term.getKey()
    if key == "up" then
      if sel > 1 then sel = sel - 1 else sel = #cur.items end
    elseif key == "down" then
      if sel < #cur.items then sel = sel + 1 else sel = 1 end
    elseif key == "\13" then
      if not cur.items[sel].items then
        cur.items[sel].selected = not cur.items[sel].selected
      else
        cur = cur.items[sel]
      end
    elseif key == "right" then
      if cur[sel].items then
        cur = cur[sel]
        sel = 1
      end
    elseif key == "left" then
      if cur.parent then
        cur = cur.parent
        sel = 1
      else
        break
      end
    end
  end

  return struct
end

return tui
