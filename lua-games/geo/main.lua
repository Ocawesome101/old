#!/usr/bin/env lua5.3
-- simple game vaguely remniscient of Geometry Dash made using LuaSDL --

--# Configuration #--

-- Set this to true if you have a fast computer (i.e. most x86 machines).
-- I've set it to false by default because this is intended to run on the
-- PinePhone, which is... not nearly as fast.
-- It is important to note that having this option disabled on a capable
-- machine will make the game less playable.
local fast = false

--# End of Configuration #--

local sdl = require("SDL")
local img = require("SDL.image")
local ttf = require("SDL.ttf")

assert(sdl.init, {sdl.flags.Video, sdl.flags.Events})
assert(ttf.init())
local font = ttf.open("unscii-16.ttf", 40)
do
  local a,b,c = img.init({img.flags.PNG})
  if not a[img.flags.PNG] then
    error(c)
  end
end

print(string.format("Running on SDL %d.%d.%d", sdl.VERSION_MAJOR, sdl.VERSION_MINOR, sdl.VERSION_PATCH))
print(fast and "Fast mode: yes" or "Fast mode: no")
print("Creating window")

local win = assert(sdl.createWindow({
  title = "Geo",
  width = 1440,
  height = 720,
  flags = {}
}))

print("Creating renderer")
local rdr = assert(sdl.createRenderer(win, 0, 0))

local function ltx(n)
  print("Loading texture: " .. n)
  return assert(img.load(n))
end

local player = ltx("player_img1.png")
local bg = rdr:createTextureFromSurface(ltx("background.png"))
local spike = ltx("spike.png")

local function draw(i, x, y)
  local _, _, w, h = i:query()
  rdr:copy(i, nil, {x=x, y=y, w=w, h=h})
end
local sprites = {}
local function render()
  rdr:setDrawColor(0xFFFFFF)
  rdr:clear()
  draw(bg, 0, 0)
  for i=1, #sprites, 1 do
    if sprites[i].shown then draw(sprites[i].img, sprites[i].x//1, sprites[i].y//1) end
  end
  rdr:present()
end

local run = true

local p = {
  img = rdr:createTextureFromSurface(player),
  x = 656,
  y = 464,
  shown = true
}
local s1 = {
  img = rdr:createTextureFromSurface(spike),
  x = 1440,
  y = 464,
  shown = true
}
local s2 = {
  img = s1.img,
  x = 1568,
  y = 464,
  shown = false
}

sprites[1] = p
sprites[2] = s1
sprites[3] = s2
sprites[4] = {
  img = true,
  x = 5,
  y = 5,
  shown = true
}

local function checkHit(s)
  if (s.x > 560 and s.x < 752 and p.y + 48 >= s.y) or (s.x > 580 and s.x < 732 and p.y + 96 >= s.y) then
    return true
  end
end

local scored = false
local function checkScored(s)
  if s.x < 400 and s.shown and not scored then
    scored = true
    return true
  end
end

::gameloop::
-- main game loop. yes, gotos.
local pjv = 0
local gndy = 464
local score = 0
scored = false
s1.x = 1440
s2.x = 1568
s2.shown = false
local last_draw = os.clock()
local b = false
while run do
  -- iterate over available events
  for e in sdl.pollEvent() do
    if e.type == sdl.event.Quit then
      run = false
    elseif e.type == sdl.event.KeyDown then
      local key = sdl.getKeyName(e.keysym.sym)
      if key == "Space" or key == "Left Ctrl" or key == "Up" then
        if pjv == 0 then
          pjv = 10
        end
      end
    elseif e.type == sdl.event.MouseButtonDown then
      if pjv == 0 then
        pjv = 10
      end
    end
  end

  if p.y < gndy or pjv > 0 then
    pjv = pjv - 0.15
    p.y = p.y - pjv
  end
  if p.y >= gndy then
    p.y = gndy
    pjv = 0
  end

  s1.x = s1.x - 4
  s2.x = s2.x - 4
  if checkHit(s1) then goto youlose end
  if s2.shown then if checkHit(s2) then goto youlose end end
  if (s2.shown and checkScored(s2)) or ((not s2.shown) and checkScored(s1)) then score = score + 1 end
  if s1.x <= -128 then scored = false s1.x = 1440 end
  if s2.x <= -128 then s2.x = 1440 scored = false if math.random(1,10) >= 5 then s2.shown = true else s2.shown = false end end
  
  sprites[4].img = rdr:createTextureFromSurface(font:renderUtf8("Score: " .. score, "solid", 0xFFFFFF))

  -- limit FPS so as to actually improve it
  local cur = os.clock()
  if cur - last_draw >= (fast and 0.001 or 0.005) then last_draw = cur render() end
  if b then sdl.delay(fast and 4 or 3) else sdl.delay(fast and 3 or 2) end b = not b
end

if not run then goto exit end

::youlose::
draw(rdr:createTextureFromSurface(font:renderUtf8("You lose! Score: " .. score .. ".", "solid", 0xFFFFFF)), 500, 300)
rdr:present()

do -- here because lua complained about jumping scopes
  local time = os.time()
  repeat
    for e in sdl.pollEvent() do
      if e.type == sdl.event.Quit then
        goto exit
      end
    end
  until os.time() - time >= 5
  goto gameloop
end

::exit::
sdl.quit()
