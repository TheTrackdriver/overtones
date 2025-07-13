-- overtones
--
-- an additive synthesizer with
-- eight partials and four
-- memory slots. the slots are
-- snapshots of the partials
-- volume level and are morphed
-- while playing.
-- 
-- k2 and k3 steps through
-- four sections.
--
-- section 1
--   e1: slot selection
--   e2: partial selection
--   e3: partial level
--   k1+k2: copy snapshot
--   k1+k3: paste snapshot
--
-- section 2, 3 and 4
--   e1: main level
--   e2: Parameter selection
--   e3: Parameter control
--
--
--
--
--
--
--
-- press K3...

engine.name = 'Overtones'
overtones_setup = include('lib/params_overtones')

music = require 'musicutil'

local popup_timer = nil
gridpage = {"grid page 1", "grid page 2", "grid page 3"}
copy_snapshot = {}

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
  key_16_8_down = false
  show_popup = false
  page = 1
  gridpage = "grid page 1"
  ramp_speed = 0.15
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

-- Grid popup window -------------------------------------
function show_popup_window(message)
  show_popup = true
  popup_message = message or ""

  if popup_timer then
    clock.cancel(popup_timer)
    popup_timer = nil
  end

  popup_timer = clock.run(function()
    clock.sleep(1)
    show_popup = false
    redraw()
  end)

  redraw()
end

-- Grid popup content ------------------------------------
function show_param_popup(param_id)
  local val = round(params:get(param_id), 2)
  local def = params:lookup_param(param_id)
  local txt = def.name .. ": " .. val
  show_popup_window(txt)
end

-- Slew for grid -----------------------------------------
function ramp_param_to_value(param_id, current_y, target_y, grid_y_min, grid_y_max, val_min, val_max, ramp_speed)
  local function grid_y_to_val(y)
    return map(y, grid_y_min, grid_y_max, val_min, val_max)
  end

  local direction = target_y > current_y and 1 or -1
  local y = current_y

  clock.run(function()
    while y ~= target_y do
      y = y + direction
      local val = grid_y_to_val(y)
      params:set(param_id, val)
      grid_redraw()
      redraw()
      clock.sleep(ramp_speed or 0.05)
    end
  end)
end

-- Step for grid -----------------------------------------
function fine_tune_param(param_id, step_size)
  local current_val = params:get(param_id)
  local new_val = current_val + step_size
  local info = params:lookup_param(param_id).controlspec

  local clamped = clamp(new_val, info.minval, info.maxval)
  params:set(param_id, new_val)

  grid_redraw()
  redraw()
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
      print("copy")
      if page == 1 then
        for i = 1,8 do
          copy_snapshot[i] = params:get("s"..slot_selection..i)
        end
      end
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
      print("paste")
      if page == 1 then
        for i = 1,8 do
          params:set("s"..slot_selection..i, copy_snapshot[i])
        end
      end
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
  if page >= 2 then
    local param_id = "amp"
    if n == 1 and d ~= 0 then
      params:delta(param_id, d)
      show_param_popup(param_id)
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
  
  if show_popup and popup_message then
    screen.level(0)
    screen.move(0,0)
    screen.line_rel(128,0)
    screen.line_rel(0,64)
    screen.line_rel(-128,0)
    screen.close()
    screen.fill()
    screen.level(15)
    screen.move(64,35)
    screen.text_center(popup_message)
    screen.blend_mode(9)
  end

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
  screen.text("l>r>e: "..round(params:get("morphMixVal") + 1, 1))
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
  screen.text("sus: "..round(params:get("sustain"), 1))
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
  screen.text("rate: "..round(params:get("panrate"), 1))
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
  screen.text("w&f: "..round(params:get("pitchmod"), 1))
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
  screen.text("rate: "..round(params:get("pitchrate"), 1))
end

--//////////////////////////////////////////////////////--
---------- GRID KEYS -------------------------------------
--//////////////////////////////////////////////////////--

g.key = function(x,y,z)
  
  if x == 16 and y == 1 then
    if z == 1 then
      gridpage = "grid page 1"
    end
  end
  
  if x == 16 and y == 2 then
    if z == 1 then
      gridpage = "grid page 2"
    end
  end
  
  if x == 16 and y == 8 then
    key_16_8_down = (z == 1)
    return
  end
  
  local step = {4, 3, 2, 1, -1, -2, -3, -4}

----------------------------------------------------------
-- GRID PAGE 1 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 1" then

-- Bars --------------------------------------------------
    if x <= 8 and z == 1 then
      local param_id = "s"..slot_selection..x
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.01)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 1, 8, 1))
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0, 1, ramp_speed)
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
        local param_id = "morphStart"
        local current_val = params:get(param_id)
        local current_y = math.floor(map(current_val, 0, 3, 1, 7))
        ramp_param_to_value(param_id, current_y, y, 1, 7, 0, 3, ramp_speed)
      end
    end
    
    if x == 12 then
      if z == 1 then
        local param_id = "morphEnd"
        local current_val = params:get(param_id)
        local current_y = math.floor(map(current_val, 0, 3, 1, 7))
        ramp_param_to_value(param_id, current_y, y, 1, 7, 0, 3, ramp_speed)
      end
    end

-- Morph lfo>rnd>env -------------------------------------
    if x == 14 and z == 1 then
      local param_id = "morphMixVal"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.025)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 2, 7, 1))
          ramp_param_to_value(param_id, current_y, y, 7, 1, 0, 2, ramp_speed)
      end
    end
        
-- Morph rate --------------------------------------------
    if x == 15 and z == 1 then
      local param_id = "morphRate"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.1)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.1, 20, 8, 1))
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.1, 20, ramp_speed)
      end
    end
  end

----------------------------------------------------------
-- GRID PAGE 2 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 2" then

-- Main volume -------------------------------------------
    if x == 1 and z == 1 then
      local param_id = "amp"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.025)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 1, 8, 1))
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0, 1, ramp_speed)
      end
    end

-- Envelope ----------------------------------------------
    if x == 3 and z == 1 then
      local param_id = "attack"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.05)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.01, 10, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.01, 10, ramp_speed)
      end
    end

    if x == 4 and z == 1 then
      local param_id = "decay"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.05)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.1, 10, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.1, 10, ramp_speed)
      end
    end

    if x == 5 and z == 1 then
      local param_id = "sustain"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.025)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 1, 8, 1))
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0, 1, ramp_speed)
      end
    end

    if x == 6 and z == 1 then
      local param_id = "release"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.05)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.1, 10, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.1, 10, ramp_speed)
      end
    end

-- Pan width modulation ----------------------------------
    if x == 8 and z == 1 then
      local param_id = "panwidth"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.025)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 1, 8, 1))
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0, 1, ramp_speed)
      end
    end
    
    if x == 9 and z == 1 then
      local param_id = "panrate"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.1)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.1, 20, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.1, 20, ramp_speed)
      end
    end
        
-- Pitch modulation --------------------------------------
    if x == 11 and z == 1 then
      local param_id = "pitchmod"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.13)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0, 26, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0, 26, ramp_speed)
      end
    end

    if x == 12 and z == 1 then
      local param_id = "pitchrate"
      if key_16_8_down then
        local step_size = step[y] or 0
        fine_tune_param(param_id, step_size * 0.1)
        show_param_popup(param_id)
        else
          local current_val = params:get(param_id)
          local current_y = math.floor(map(current_val, 0.1, 20, 8, 1) + 0.5)
          ramp_param_to_value(param_id, current_y, y, 8, 1, 0.1, 20, ramp_speed)
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

-- Led levels --------------------------------------------
  led_ramp_start = 5
  led_background = 1
  led_switch = 5

-- Page selectors ----------------------------------------
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

-- Alt key -----------------------------------------------
    g:led(16, 8, led_switch)

----------------------------------------------------------
-- GRID PAGE 1 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 1" then

-- Bars --------------------------------------------------
    for x = 1,8 do
      for y = 1,7 do
      g:led(x, y, led_background)
      end
      grid_bar_val = math.floor(map(params:get("s"..slot_selection..x), 0, 1, 8, 1) + 0.5)
      for y = grid_bar_val,8 do
        if params:get("s"..slot_selection..x) == 0 then
          g:led(x, y, led_background)
          else
            g:led(x, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
        end
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

-- Morph lfo>rnd>env -------------------------------------
    grid_morphmix_val = math.floor(map(params:get("morphMixVal"), 0, 2, 7, 1))
    for y = 1,grid_morphmix_val do
      g:led(14, y - 1, led_background)
    end
    for y = grid_morphmix_val, 7 do
      g:led(14, y, 3)
    end
    
    if grid_morphmix_val == 7 then
      g:led(14, 7, 15)
      else
        g:led(14, 7, 6)
    end
    if grid_morphmix_val == 4 then
      g:led(14, 4, 15)
      else
        g:led(14, 4, 6)
    end
    if grid_morphmix_val == 1 then
      g:led(14, 1, 15)
      else
        g:led(14, 1, 6)
    end
    
-- Morph rate --------------------------------------------
    grid_morphrate_val = math.floor(map(params:get("morphRate"), 0.1, 20, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(15, y, led_background)
    end
    for y = grid_morphrate_val,8 do
      g:led(15, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
  end

----------------------------------------------------------
-- GRID PAGE 2 -------------------------------------------
----------------------------------------------------------

  if gridpage == "grid page 2" then

-- Main volume -------------------------------------------
    grid_amp_val = math.floor(map(params:get("amp"), 0, 1, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(1, y, led_background)
    end
    for y = grid_amp_val, 8 do
      if params:get("amp") == 0 then
        g:led(1, y, led_background)
        else
          g:led(1, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
      end
    end

-- Envelope ----------------------------------------------
    grid_attack_val = math.floor(map(params:get("attack"), 0.01, 10, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(3, y, led_background)
    end
    for y = grid_attack_val, 8 do
      g:led(3, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
    
    grid_decay_val = math.floor(map(params:get("decay"), 0.1, 10, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(4, y, led_background)
    end
    for y = grid_decay_val, 8 do
      g:led(4, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
    
    grid_sustain_val = math.floor(map(params:get("sustain"), 0, 1, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(5, y, led_background)
    end
    for y = grid_sustain_val, 8 do
      if params:get("sustain") == 0 then
        g:led(5, y, led_background)
        else
          g:led(5, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
      end
    end
    
    grid_release_val = math.floor(map(params:get("release"), 0.1, 10, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(6, y, led_background)
    end
    for y = grid_release_val, 8 do
      g:led(6, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
  
-- Pan width modulation ----------------------------------
    grid_panwidth_val = math.floor(map(params:get("panwidth"), 0, 1, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(8, y, led_background)
    end
    for y = grid_panwidth_val, 8 do
      if params:get("panwidth") == 0 then
        g:led(8, y, led_background)
        else
          g:led(8, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
      end
    end
    
    grid_panrate_val = math.floor(map(params:get("panrate"), 0.1, 20, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(9, y, led_background)
    end
    for y = grid_panrate_val, 8 do
      g:led(9, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
    
-- Pitch modulation --------------------------------------
    grid_pitchmod_val = math.floor(map(params:get("pitchmod"), 0, 26, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(11, y, led_background)
    end
    for y = grid_pitchmod_val, 8 do
      if params:get("pitchmod") == 0 then
        g:led(11, y, led_background)
        else
          g:led(11, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
      end
    end
    
    grid_pitchrate_val = math.floor(map(params:get("pitchrate"), 0.1, 20, 8, 1) + 0.5)
    for y = 1,7 do
      g:led(12, y, led_background)
    end
    for y = grid_pitchrate_val, 8 do
      g:led(12, y, math.floor(map(y, 8, 1, led_ramp_start, 15) + 0.5))
    end
  end
  g:refresh()
end

