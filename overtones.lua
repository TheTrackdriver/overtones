-- Overtones
-- ------------------------------
-- An additive synthesizer with
-- eight partials and four
-- memory slots. The slots are
-- snapshots of the partials
-- volume level and are morphed
-- while playing.
-- 
-- K2: Partial editor
--      E1: Slot selection
--      E2: Partial selection
--      E3: Partial level
-- 
-- K3: Parameter editor
--      E2: Parameter selection
--      E3: Parameter adjustment

engine.name = 'Overtones'
overtones_setup = include('lib/params_overtones')

music = require 'musicutil'

local popup_timer = nil
gridpage = {"grid page 1", "grid page 2"}

g = grid.connect()

m = midi.connect()

--//////////////////////////////////////////////////////--
---------- MIDI ------------------------------------------
--//////////////////////////////////////////////////////--

local function note_on(note_id, note_num, vel)
  engine.noteOn(note_id, music.note_num_to_freq(note_num), vel)
end

local function note_off(note_id)
  engine.noteOff(note_id)
end

local function note_off_all()
  engine.noteOffAll()
end

local function note_kill_all()
  engine.noteKillAll()
end

m.event = function(data)
  local msg = midi.to_msg(data)

  if msg.type == "note_on" and msg.vel > 0 then
    note_on(msg.note, msg.note, msg.vel / 127)

  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    note_off(msg.note, msg.note)
  end
end

--//////////////////////////////////////////////////////--
---------- INIT ------------------------------------------
--//////////////////////////////////////////////////////--

function init()
  overtones_setup.add_params()
  norns.enc.sens(1,10)
  norns.enc.sens(2,10)
  parm_selection = 1
  slot_selection = 1
  key1_down = false
  amp_popup = false
  page = 1
  gridpage = "grid page 1"
  redraw()
  grid_redraw()
end

--//////////////////////////////////////////////////////--
---------- UTILS -----------------------------------------
--//////////////////////////////////////////////////////--

-- Clamp values ------------------------------------------
function clamp(val, low, high)
    return math.max(low, math.min(val, high))
end

-- Remapping ranges --------------------------------------
function map(x, in_min, in_max, out_min, out_max)
	return out_min + (x - in_min)*(out_max - out_min)/(in_max - in_min)
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

-- Amp popup ---------------------------------------------
function show_amp_popup()
  amp_popup = true

  if popup_timer then
    clock.cancel(popup_timer)
    popup_timer = nil
  end

  popup_timer = clock.run(function()
    clock.sleep(1)
    amp_popup = false
    redraw()
  end)
end

-- Print all stored partials -----------------------------
function show_spectrum()
  print("slot1:",params:get("s11"),params:get("s12"),params:get("s13"),params:get("s14"),params:get("s15"),params:get("s16"),params:get("s17"),params:get("s18"))
  print("slot2:",params:get("s21"),params:get("s22"),params:get("s23"),params:get("s24"),params:get("s25"),params:get("s26"),params:get("s27"),params:get("s28"))
  print("slot3:",params:get("s31"),params:get("s32"),params:get("s33"),params:get("s34"),params:get("s35"),params:get("s36"),params:get("s37"),params:get("s38"))
  print("slot4:",params:get("s41"),params:get("s42"),params:get("s43"),params:get("s44"),params:get("s45"),params:get("s46"),params:get("s47"),params:get("s48"))
end

--//////////////////////////////////////////////////////--
---------- KEYS & ENCODERS -------------------------------
--//////////////////////////////////////////////////////--

function key(n,z)
  if n == 1 and z == 1 then
    key1_down = true
  elseif n == 1 and z == 0 then
    key1_down = false
  end
  
  if n == 2 and z == 1 then
    if key1_down then
      print("placeholder1\nalt + key2")
      else
        page = clamp(page - z, 1, 4)
        slot_selection = 1
        parm_selection = 1
        print("page: "..page)
        print("key2")
    end
  end
  
  if n == 3 and z == 1 then
    if key1_down then
      print("placeholder2\nalt + key3")
      else
        page = clamp(page + z, 1, 4)
        parm_selection = 1
        print("page: "..page)
        print("key3")
    end
  end
  grid_redraw()
  redraw()
end

function enc(n,d)
  if page == 3 or page == 4 then
    if n == 1 and d ~= 0 then
      show_amp_popup()
      params:delta("amp", d)
    end
  end
  
  
  if page == 1 then
    if n == 1 then
      slot_selection = clamp(slot_selection + d, 1, 4)
      print("slot: "..slot_selection)

    elseif n == 2 then
      parm_selection = clamp(parm_selection + d, 1, 8)

    elseif n == 3 then
        params:delta("s"..slot_selection..parm_selection, d)
    end
  end
  
  if page == 2 then
    if n == 2 then
      parm_selection = clamp(parm_selection + d, 1, 4)
      
    elseif n == 3 then
      if parm_selection == 1 then
        params:delta("morphStart", d)
        
      elseif parm_selection == 2 then
        params:delta("morphEnd", d)
      
      elseif parm_selection == 3 then
        params:delta("morphMixVal", d)
        
      elseif parm_selection == 4 then
        params:delta("morphRate", d)
      end
    end
  end

  if page == 3 then
    if n == 1 then
      params:delta("amp", d)
    end
    
    if n == 2 then
      parm_selection = clamp(parm_selection + d, 1, 4)

    elseif n == 3 then
      if parm_selection == 1 then
        params:delta("attack", d)
        
      elseif parm_selection == 2 then
        params:delta("decay", d)
          
      elseif parm_selection == 3 then
        params:delta("sustain", d)
          
      elseif parm_selection == 4 then
        params:delta("release", d)
      end
    end
  end

  if page == 4 then
    if n == 1 then
      params:delta("amp", d)
    end
    
    if n == 2 then
      parm_selection = clamp(parm_selection + d, 1, 4)
    elseif n == 3 then
      
      if parm_selection == 1 then
        params:delta("panwidth", d)
        
      elseif parm_selection == 2 then
        params:delta("panrate", d)
        
      elseif parm_selection == 3 then
        params:delta("pitchmod", d)
        
      elseif parm_selection == 4 then
        params:delta("pitchrate", d)
      end
    end
  end
  grid_redraw()
  redraw()
end

--//////////////////////////////////////////////////////--
---------- GRAPHICS --------------------------------------
--//////////////////////////////////////////////////////--

function redraw()
  screen.clear()

  if page == 1 or page == 2 then
    draw_bars()
    draw_slots()
    morph_range_arrows()
    
    draw_text_morphStart()
    draw_text_morphEnd()
    draw_text_morphMixVal()
    draw_text_morphRate()
  end
  
  if page == 3 or page == 4 then
    draw_text_amp()
    draw_text_attack()
    draw_text_decay()
    draw_text_sustain()
    draw_text_release()
    
    draw_text_panwidth()
    draw_text_panrate()
    draw_text_pitchmod()
    draw_text_pitchrate()
  end
  screen.update()
end

function draw_bars()
  screen.line_width(1)
  if page == 1 then
      screen.level(15)
      elseif page == 2 then
        screen.level(1)
      end
      for parm_selection = 1,8 do
        screen.move((parm_selection * 8) - 5, 62)
        screen.line_rel(0, (params:get("s"..slot_selection..parm_selection) + 0.02) * -59)
        screen.stroke()
      end
      
      if page == 1 then
        screen.level(15)
      elseif page == 2 then
        screen.level(0)
      end
      screen.line_width(1)
      screen.move((parm_selection * 8) - 7,61)
      screen.line_rel(0,3)
      screen.line_rel(4,0)
      screen.line_rel(0,-3)
      screen.stroke()
end
    

function draw_slots()
  x = 68
  y = 9
  if page == 1 or page == 2 then
    screen.line_width(1)
    for i = 1,4 do
      screen.level(1)
      screen.move(x + 1, (i * 14) - 4)
      screen.line_rel(4,0)
      screen.line_rel(0,4)
      screen.line_rel(-4,0)
      screen.close()
      screen.stroke()
    end
    
    if slot_selection == 1 then
      if page == 1 then
      screen.level(15)
      elseif page == 2 then
        screen.level(1)
      end
      screen.move(x,y)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
    end
    
    if slot_selection == 2 then
      if page == 1 then
      screen.level(15)
      elseif page == 2 then
        screen.level(1)
      end
      screen.move(x,y + 14)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
    end

    if slot_selection == 3 then
      if page == 1 then
      screen.level(15)
      elseif page == 2 then
        screen.level(1)
      end
      screen.move(x,y + 28)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
    end
    
    if slot_selection == 4 then
      if page == 1 then
      screen.level(15)
      elseif page == 2 then
        screen.level(1)
      end
      screen.move(x,y + 42)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
    end
  end
end

function morph_range_arrows()
  xstart = 63
  xend = xstart + 15
  ystart = round(params:get("morphStart") * 14 + 8, 0)
  yend = round(params:get("morphEnd") * 14 + 8, 0)

  if page == 2 and parm_selection == 1 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(xstart, ystart)
  screen.line_rel(3,3)
  screen.line_rel(-3,3)
  screen.close()
  screen.fill()
  
  if page == 2 and parm_selection == 2 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(xend, yend)
  screen.line_rel(-3,3)
  screen.line_rel(3,3)
  screen.close()
  screen.fill()
end

--//////////////////////////////////////////////////////--
---------- TEXT ------------------------------------------
--//////////////////////////////////////////////////////--

-- Morph -------------------------------------------------
function draw_text_morphStart()
  if page == 2 and parm_selection == 1 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(82,14)
  screen.text("start: "..round(params:get("morphStart") + 1, 1))
end

function draw_text_morphEnd()
  if page == 2 and parm_selection == 2 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(82,28)
  screen.text("end: "..round(params:get("morphEnd") + 1, 1))
end

function draw_text_morphMixVal()
  if page == 2 and parm_selection == 3 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(82,42)
  screen.text("lin>rnd: "..round(params:get("morphMixVal"), 1))
end

function draw_text_morphRate()
  if page == 2 and parm_selection == 4 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 1 then
    screen.level(1)
  end
  screen.move(82,56)
  screen.text("rate:"..round(params:get("morphRate"), 1))
end

-- Envelope ----------------------------------------------
function draw_text_attack()
  if page == 3 and parm_selection == 1 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 4 then
    screen.level(1)
  end
  screen.move(2,14)
  screen.text("att: "..round(params:get("attack"), 2))
end

function draw_text_decay()
  if page == 3 and parm_selection == 2 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 4 then
    screen.level(1)
  end
  screen.move(2,28)
  screen.text("dec: "..round(params:get("decay"), 2))
end

function draw_text_sustain()
  if page == 3 and parm_selection == 3 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 4 then
    screen.level(1)
  end
  screen.move(2,42)
  screen.text("sus: "..round(params:get("sustain"), 2))
end

function draw_text_release()
  if page == 3 and parm_selection == 4 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 4 then
    screen.level(1)
  end
  screen.move(2,56)
  screen.text("rel: "..round(params:get("release"), 2))
end

-- Pan width modulation ----------------------------------
function draw_text_panwidth()
  if page == 4 and parm_selection == 1 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 3 then
    screen.level(1)
  end
  screen.move(82,14)
  screen.text("width: "..round(params:get("panwidth"), 1))
end

function draw_text_panrate()
  if page == 4 and parm_selection == 2 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 3 then
    screen.level(1)
  end
  screen.move(82,28)
  screen.text("rate: "..round(params:get("panrate"), 2))
end

-- Pitch modulation --------------------------------------
function draw_text_pitchmod()
  if page == 4 and parm_selection == 3 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 3 then
    screen.level(1)
  end
  screen.move(82,42)
  screen.text("w&f: "..params:get("pitchmod"))
end

function draw_text_pitchrate()
  if page == 4 and parm_selection == 4 then
    screen.level(15)
    else
      screen.level(3)
  end
  if page == 3 then
    screen.level(1)
  end
  screen.move(82,56)
  screen.text("rate: "..round(params:get("pitchrate"), 2))
end

-- Amp popup ---------------------------------------------

function draw_text_amp()
    if amp_popup == true then
      screen.level(0)
      screen.move(34,21)
      screen.line_rel(60,0)
      screen.line_rel(0,25)
      screen.line_rel(-60,0)
      screen.close()
      screen.fill()
      screen.level(4)
      screen.move(34,21)
      screen.line_rel(60,0)
      screen.line_rel(0,25)
      screen.line_rel(-60,0)
      screen.close()
      screen.stroke()
      screen.level(15)
      screen.move(44,35)
      screen.text("main: "..round(params:get("amp"), 2))
      screen.blend_mode(9)
    end
    if amp_popup == false then
      screen.level(0)
    end
end

--//////////////////////////////////////////////////////--
---------- GRID KEYS -------------------------------------
--//////////////////////////////////////////////////////--

g.key = function(x,y,z)
  
  if x == 16 and y == 1 then
    gridpage = "grid page 1"
  elseif x == 16 and y == 2 then
    gridpage = "grid page 2"
  end
  
----------------------------------------------------------
-- GRID PAGE 1 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 1" then

-- Bars --------------------------------------------------
    if x <= 8 then
      if z == 1 then
        params:set("s"..slot_selection..x, map(y, 8, 1, 0, 1))
      end
    end

-- Slot selection ----------------------------------------
    if z == 1 then
      if x == 9 and y == 1 then
        slot_selection = 1
        
      elseif x == 9 and y == 3 then
        slot_selection = 2
        
      elseif x == 9 and y == 5 then
        slot_selection = 3
        
      elseif x == 9 and y == 7 then
        slot_selection = 4
      end
    end

-- Morph range -------------------------------------------
    if x == 10 then
      if z == 1 then
        params:set("morphStart", map(y, 1, 7, 0, 3))
      end
    end

    if x == 12 then
      if z == 1 then
        params:set("morphEnd", map(y, 1, 7, 0, 3))
      end
    end

-- Morph lin>rnd -----------------------------------------
    if x == 14 then
      if z == 1 then
        params:set("morphMixVal", map(y, 8, 1, 0, 1))
      end
    end
        
-- Morph rate --------------------------------------------
    if x == 15 then
      if z == 1 then
        params:set("morphRate", map(y, 8, 1, 0.1, 20))
      end
    end
  end

----------------------------------------------------------
-- GRID PAGE 2 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 2" then

-- Main volume -------------------------------------------
    if z == 1 then  
      if x == 1 then
        params:set("amp", map(y, 8, 1, 0, 1))
      end
    end

-- Envelope ----------------------------------------------
    if x == 3 then
      if z == 1 then
        params:set("attack", map(y, 8, 1, 0.01, 10))
      end
    end
        
    if x == 4 then
      if z == 1 then
        params:set("decay", map(y, 8, 1, 0.1, 10))
      end
    end
        
    if x == 5 then
      if z == 1 then
        params:set("sustain", map(y, 8, 1, 0, 1))
      end
    end
        
    if x == 6 then
      if z == 1 then
        params:set("release", map(y, 8, 1, 0.1, 10))
      end
    end

-- Pan width modulation ----------------------------------
    if x == 8 then
      if z == 1 then
        params:set("panwidth", map(y, 8, 1, 0, 1))
      end
    end
    
    if x == 9 then
      if z == 1 then
        params:set("panrate", map(y, 8, 1, 0.1, 20))
      end
    end
        
-- Pitch modulation --------------------------------------
    if x == 11 then
      if z == 1 then
        params:set("pitchmod", map(y, 8, 1, 0, 26))
      end
    end

    if x == 12 then
      if z == 1 then
        params:set("pitchrate", map(y, 8, 1, 0.1, 20))
      end
    end
  end
  grid_redraw()
  redraw()
end

--//////////////////////////////////////////////////////--
---------- GRID DISPLAY ----------------------------------
--//////////////////////////////////////////////////////--

function grid_redraw()
  g:all(0)
  
  led_ramp_start = 1
  led_background = 1
  led_switch = 5
  
  if gridpage == "grid page 1" then
        g:led(16, 1, 15)
        else
          g:led(16, 1, led_switch)
  end
  
  if gridpage == "grid page 2" then
        g:led(16, 2, 15)
        else
          g:led(16, 2, led_switch)
  end

----------------------------------------------------------
-- GRID PAGE 1 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 1" then

-- Bars --------------------------------------------------
    for x = 1,8 do
      grid_bar_val = math.floor(map(params:get("s"..slot_selection..x), 0, 1, 8, 1))
      for y = grid_bar_val,8 do
--        if grid_bar_val == 8 then
--          g:led(x, y, 7)
--          else
            g:led(x, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--        end
      end
    end
    
-- Slot selection ----------------------------------------
    if slot_selection == 1 then
      g:led(9, 1, 15)
      else
        g:led(9, 1, led_switch)
    end
    
    if slot_selection == 2 then
      g:led(9, 3, 15)
      else
        g:led(9, 3, led_switch)
    end
    
    if slot_selection == 3 then
      g:led(9, 5, 15)
      else
        g:led(9, 5, led_switch)
    end
    
    if slot_selection == 4 then
      g:led(9, 7, 15)
      else
        g:led(9, 7, led_switch)
    end

-- Morph range -------------------------------------------
    grid_morphstart_val = math.floor(map(params:get("morphStart"), 0, 3, 1, 7))
    grid_morphend_val = math.floor(map(params:get("morphEnd"), 0, 3, 1, 7))
    
    g:led(10, grid_morphstart_val, 15)
    g:led(12, grid_morphend_val, 15)
    
    local lower = math.min(grid_morphstart_val, grid_morphend_val)
    local upper = math.max(grid_morphstart_val, grid_morphend_val)
    
    for y = 1, 7 do
      if y >= lower and y <= upper then
        g:led(11, y, 15)
        else
          g:led(11, y, 5)
      end
    end
  
-- Morph lin>rnd -----------------------------------------
    grid_morphlinrnd_val = math.floor(map(params:get("morphMixVal"), 0, 1, 8, 1))
    for y = grid_morphlinrnd_val, 8 do
--      if grid_morphlinrnd_val == 8 then
--        g:led(14, y, 7)
--        else
          g:led(14, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_morphlinrnd_val do
      g:led(14, y - 1, led_background)
    end
    
-- Morph rate --------------------------------------------
    grid_morphrate_val = math.floor(map(params:get("morphRate"), 0.1, 20, 8, 1) + 0.5)
    for y = grid_morphrate_val, 8 do
--      if grid_morphrate_val == 8 then
--        g:led(15, y, 7)
--        else
          g:led(15, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_morphrate_val do
      g:led(15, y - 1, led_background)
    end
  end

----------------------------------------------------------
-- GRID PAGE 2 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 2" then

-- Main volume -------------------------------------------
    grid_amp_val = math.floor(map(params:get("amp"), 0, 1, 8, 1))
    for y = grid_amp_val, 8 do
--      if grid_amp_val == 8 then
--        g:led(1, y, 7)
--        else
          g:led(1, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_amp_val do
      g:led(1, y - 1, led_background)
    end

-- Envelope ----------------------------------------------
    grid_attack_val = math.floor(map(params:get("attack"), 0.01, 10, 8, 1) + 0.5)
    for y = grid_attack_val, 8 do
--      if grid_attack_val == 8 then
--        g:led(3, y, 7)
--        else
          g:led(3, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_attack_val do
      g:led(3, y - 1, led_background)
    end
    
    grid_decay_val = math.floor(map(params:get("decay"), 0.1, 10, 8, 1) + 0.5)
    for y = grid_decay_val, 8 do
--      if grid_decay_val == 8 then
--        g:led(4, y, 7)
--        else
          g:led(4, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_decay_val do
      g:led(4, y - 1, led_background)
    end
    
    grid_sustain_val = math.floor(map(params:get("sustain"), 0, 1, 8, 1))
    for y = grid_sustain_val, 8 do
--      if grid_sustain_val == 8 then
--        g:led(5, y, 7)
--        else
          g:led(5, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_sustain_val do
      g:led(5, y - 1, led_background)
    end
    
    grid_release_val = math.floor(map(params:get("release"), 0.1, 10, 8, 1) + 0.5)
    for y = grid_release_val, 8 do
--      if grid_release_val == 8 then
--        g:led(6, y, 7)
--        else
          g:led(6, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_release_val do
      g:led(6, y - 1, led_background)
    end
  
-- Pan width modulation ----------------------------------
    grid_panwidth_val = math.floor(map(params:get("panwidth"), 0, 1, 8, 1))
    for y = grid_panwidth_val, 8 do
--      if grid_panwidth_val == 8 then
--        g:led(8, y, 7)
--        else
          g:led(8, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_panwidth_val do
      g:led(8, y - 1, led_background)
    end
    
    grid_panrate_val = math.floor(map(params:get("panrate"), 0.1, 20, 8, 1) + 0.5)
    for y = grid_panrate_val, 8 do
--      if grid_panrate_val == 8 then
--        g:led(9, y, 7)
--        else
          g:led(9, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_panrate_val do
      g:led(9, y - 1, led_background)
    end
    
-- Pitch modulation --------------------------------------
    grid_pitchmod_val = math.floor(map(params:get("pitchmod"), 0, 26, 8, 1) + 0.5)
    for y = grid_pitchmod_val, 8 do
--      if grid_pitchmod_val == 8 then
--        g:led(11, y, 7)
--        else
          g:led(11, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_pitchmod_val do
      g:led(11, y - 1, led_background)
    end
    
    grid_pitchrate_val = math.floor(map(params:get("pitchrate"), 0.1, 20, 8, 1) + 0.5)
    for y = grid_pitchrate_val, 8 do
--      if grid_pitchrate_val == 8 then
--        g:led(12, y, 7)
--        else
          g:led(12, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
--      end
    end
    for y = 1,grid_pitchrate_val do
      g:led(12, y - 1, led_background)
    end
  end
  g:refresh()
end

