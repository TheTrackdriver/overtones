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
local pageSelect = {"partials", "parameters"}

g = grid.connect()

m = midi.connect()

----------------------------------------------------------
---------- MIDI ------------------------------------------
----------------------------------------------------------

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

----------------------------------------------------------
---------- INIT ------------------------------------------
----------------------------------------------------------

function init()
  overtones_setup.add_params()
  norns.enc.sens(1,10)
  norns.enc.sens(2,10)
  parm_selection = 1
  slot_selection = 1
  key1_down = false
  page = "partials"
  grid_redraw()
  redraw()
end

----------------------------------------------------------
---------- UTILS -----------------------------------------
----------------------------------------------------------

function clamp(val, low, high)
    return math.max(low, math.min(val, high))
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

function show_spectrum()
  print("slot1:",params:get("s11"),params:get("s12"),params:get("s13"),params:get("s14"),params:get("s15"),params:get("s16"),params:get("s17"),params:get("s18"))
  print("slot2:",params:get("s21"),params:get("s22"),params:get("s23"),params:get("s24"),params:get("s25"),params:get("s26"),params:get("s27"),params:get("s28"))
  print("slot3:",params:get("s31"),params:get("s32"),params:get("s33"),params:get("s34"),params:get("s35"),params:get("s36"),params:get("s37"),params:get("s38"))
  print("slot4:",params:get("s41"),params:get("s42"),params:get("s43"),params:get("s44"),params:get("s45"),params:get("s46"),params:get("s47"),params:get("s48"))
end

----------------------------------------------------------
---------- KEYS & ENCODERS -------------------------------
----------------------------------------------------------



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
        page = pageSelect[1]
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
        page = pageSelect[2]
        parm_selection = 1
        print("page: "..page)
        print("key3")
    end
  end
  redraw()
end

function enc(n,d)
  if page == "partials" then
    if n == 1 then
      slot_selection = clamp(slot_selection + d, 1, 4)
      print(slot_selection)

    elseif n == 2 then
      parm_selection = clamp(parm_selection + d, 1, 12)

    elseif n == 3 then
      if parm_selection <=  8 then
        params:delta("s"..slot_selection..parm_selection, d)
        
      elseif parm_selection == 9 then
        params:delta("morphStart", d)
        
      elseif parm_selection == 10 then
        params:delta("morphEnd", d)
      
      elseif parm_selection == 11 then
        params:delta("morphMixVal", d)
        
      elseif parm_selection == 12 then
        params:delta("morphRate", d)
        
      end
    end
  end
  
  if page == "parameters" then
      if n == 2 then
        parm_selection = clamp(parm_selection + d, 1, 9)
      elseif n == 3 then
        
        if parm_selection == 1 then
          params:delta("amp", d)
          
        elseif parm_selection == 2 then
          params:delta("attack", d)
              
        elseif parm_selection == 3 then
          params:delta("decay", d)
              
        elseif parm_selection == 4 then
          params:delta("sustain", d)
        
        elseif parm_selection == 5 then
          params:delta("release", d)
        
        elseif parm_selection == 6 then
          params:delta("panwidth", d)
        
        elseif parm_selection == 7 then
          params:delta("panrate", d)
        
        elseif parm_selection == 8 then
          params:delta("pitchmod", d)
        
        elseif parm_selection == 9 then
          params:delta("pitchrate", d)
        end
      end
  end
  redraw()
  grid_redraw()
end

----------------------------------------------------------
---------- GRAPHICS --------------------------------------
----------------------------------------------------------

function redraw()
  screen.clear()
  if page == "partials" then
    draw_bars()
    draw_selection()
    draw_slots()
    morph_start_arrow()
    morph_end_arrow()
    draw_morphMixVal()
    draw_morphStart()
    draw_morphEnd()
    draw_morphRate()
  
  elseif page == "parameters" then
    screen.clear()
    
    draw_text_env()
    draw_text_amp()
    draw_text_attack()
    draw_text_decay()
    draw_text_sustain()
    draw_text_release()
    
    draw_text_mod()
    draw_text_panwidth()
    draw_text_panrate()
    draw_text_pitchmod()
    draw_text_pitchrate()
  end
  screen.update()
end

function draw_bars()
  if page == "partials" and parm_selection <= 8 then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.line_width(1)
  for parm_selection = 1,8 do
    screen.move((parm_selection * 8) + 27, 62)
    screen.line_rel(0, (params:get("s"..slot_selection..parm_selection) + 0.02) * -59)
    screen.stroke()
  end
end

function draw_selection()
  if page == "partials" and parm_selection <= 8 then
    screen.level(15)
    else
      screen.level(0)
  end
  screen.line_width(1)
  screen.move((parm_selection * 8) + 25,61)
  screen.line_rel(0,3)
  screen.line_rel(4,0)
  screen.line_rel(0,-3)
  screen.stroke()
end

function draw_slots()
  if page == "partials" then
    screen.line_width(1)
  for i = 1,4 do
    screen.level(2)
    screen.move(13, (i * 14) - 4)
    screen.line_rel(4,0)
    screen.line_rel(0,4)
    screen.line_rel(-4,0)
    screen.close()
    screen.stroke()
  end
  
    if slot_selection == 1 then
      screen.level(15)
      screen.move(12,9)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
    elseif slot_selection ~= 1 then
      screen.level(2)
    end
    
    if slot_selection == 2 then
      screen.level(15)
      screen.move(12,23)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
      else
        screen.level(2)
    end
    
    if slot_selection == 3 then
      screen.level(15)
      screen.move(12,37)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
      else
        screen.level(2)
    end
    
    if slot_selection == 4 then
      screen.level(15)
      screen.move(12,51)
      screen.line_rel(5,0)
      screen.line_rel(0,5)
      screen.line_rel(-5,0)
      screen.close()
      screen.fill()
      else
        screen.level(2)
    end
  end
end

function morph_start_arrow()
  if page == "partials" then
    screen.level(7)
  end
  screen.move(7,(params:get("morphStart") * 14) + 8)
  screen.line_rel(3,3)
  screen.line_rel(-3,3)
  screen.close()
  screen.fill()
end

function morph_end_arrow()
  if page == "partials" then
    screen.level(7)
  end
  screen.move(22,(params:get("morphEnd") * 14) + 8)
  screen.line_rel(-3,3)
  screen.line_rel(3,3)
  screen.close()
  screen.fill()
end

----------------------------------------------------------
---------- TEXT ------------------------------------------
----------------------------------------------------------

-- Morph -------------------------------------------------

function draw_morphStart()
  if parm_selection == 9 and page == "partials" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(100,9)
  screen.text("s: "..round(params:get("morphStart") + 1, 1))
end

function draw_morphEnd()
  if parm_selection == 10 and page == "partials" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(100,23)
  screen.text("e: "..round(params:get("morphEnd") + 1, 1))
end

function draw_morphMixVal()
  if parm_selection == 11 and page == "partials" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(100,37)
  screen.text("m: "..round(params:get("morphMixVal"), 1))
end

function draw_morphRate()
  if parm_selection == 12 and page == "partials" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(100,51)
  screen.text("r: "..round(params:get("morphRate"), 1))
end

-- Envelope ----------------------------------------------

function draw_text_env()
  if page == "parameters" then
    screen.level(7)
--    screen.font_face(25)
--    screen.font_size(6)
    screen.move(1,6)
    screen.text("envelope")
    screen.move(0,8)
    screen.line_rel(27,0)
    screen.move(30,8)
    screen.line_rel(8,0)
    screen.stroke()
  end
end

function draw_text_amp()
  if parm_selection == 1 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(1,17)
  screen.text("vol: "..round(params:get("amp"), 2))
end

function draw_text_attack()
  if parm_selection == 2 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(1,28)
  screen.text("a: "..round(params:get("attack"), 2))
end

function draw_text_decay()
  if parm_selection == 3 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(1,39)
  screen.text("d: "..round(params:get("decay"), 2))
end

function draw_text_sustain()
  if parm_selection == 4 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(1,50)
  screen.text("s: "..round(params:get("sustain"), 2))
end

function draw_text_release()
  if parm_selection == 5 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(1,61)
  screen.text("r: "..round(params:get("release"), 2))
end

-- Modulation --------------------------------------------

function draw_text_mod()
  if page == "parameters" then
    screen.level(7)
--    screen.font_face(25)
--    screen.font_size(6)
    screen.move(84,6)
    screen.text("modulation")
    screen.move(128,8)
    screen.line_rel(-73,0)
    screen.stroke()
  end
end

function draw_text_panwidth()
  if parm_selection == 6 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(55,17)
  screen.text("sprd: "..round(params:get("panwidth"), 1))
end

function draw_text_panrate()
  if parm_selection == 7 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(98,17)
  screen.text("r: "..round(params:get("panrate"), 1))
end

function draw_text_pitchmod()
  if parm_selection == 8 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(55,28)
  screen.text("w&f: "..params:get("pitchmod"))
end

function draw_text_pitchrate()
  if parm_selection == 9 and page == "parameters" then
    screen.level(15)
    else
      screen.level(2)
  end
  screen.move(98,28)
  screen.text("r: "..round(params:get("pitchrate"), 1))
end

----------------------------------------------------------
---------- GRID DISPLAY ----------------------------------
----------------------------------------------------------

function grid_redraw()
  g:refresh()
end

----------------------------------------------------------
---------- GRID KEYS -------------------------------------
----------------------------------------------------------
