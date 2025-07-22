local Overtones = {}
local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'

function Overtones.add_params()
  params:add_separator("envelope")
  params:add_control("amp", "main level", controlspec.new(0 , 1, 'lin', 0 , 0.57, ''))
  params:set_action("amp", function(x) engine.amp(x) end)
  params:add_control("attack", "attack", controlspec.new(0.01, 10, 'lin', 0, 0.01, 's'))
  params:set_action("attack", function(x) engine.attack(x) end)
  params:add_control("decay", "decay", controlspec.new(0.1, 10, 'lin', 0, 0.3, 's'))
  params:set_action("decay", function(x) engine.decay(x) end)
  params:add_control("sustain", "sustain", controlspec.new(0, 1, 'lin', 0, 0.7, ''))
  params:set_action("sustain", function(x) engine.sustain(x) end)
  params:add_control("release", "release", controlspec.new(0.1, 10, 'lin', 0, 3, 's'))
  params:set_action("release", function(x) engine.release(x) end)
  
  params:add_separator("morph")
  params:add_control("morphMixVal", "lfo>rnd>env", controlspec.new(0 , 2, 'lin', 0 , 0, ''))
  params:set_action("morphMixVal", function(x) engine.morphMixVal(x) end)
  params:add_control("morphRate", "morph rate", controlspec.new(0.1 , 20, 'lin', 0 , 4, 's'))
  params:set_action("morphRate", function(x) engine.morphRate(x) end)
  params:add_control("morphStart", "morph start", controlspec.new(0, 3, 'lin', 0, 0, ''))
  params:set_action("morphStart", function(x) engine.morphStart(x) end)
  params:add_control("morphEnd", "morph end", controlspec.new(0, 3, 'lin', 0, 0, ''))
  params:set_action("morphEnd", function(x) engine.morphEnd(x) end)
  
  params:add_separator("modulation")
  params:add_control("panwidth", "pan mod width", controlspec.new(0, 1, 'lin', 0, 0, ''))
  params:set_action("panwidth", function(x) engine.panwidth(x) end)
  params:add_control("panrate", "pan mod rate", controlspec.new(0.1, 20, 'lin', 0, 8, ''))
  params:set_action("panrate", function(x) engine.panrate(x) end)
  params:add_control("pitchmod", "pitch mod depth", controlspec.new(0, 26, 'lin', 0, 0, 'hz'))
  params:set_action("pitchmod", function(x) engine.pitchmod(x) end)
  params:add_control("pitchrate", "pitch mod rate", controlspec.new(0.1, 20, 'lin', 0, 4, ''))
  params:set_action("pitchrate", function(x) engine.pitchrate(x) end)
  
  params:add_separator("partials")
  params:add_group("partialsgroup", "partials", 36)
  params:add_separator("snapshot [1]")
  params:add_control("s11", "[1] partial 1", controlspec.new(0, 1, 'lin', 0, 1, ''))
  for i = 2,8 do
    params:add_control("s1"..i, "[1] partial "..i, controlspec.new(0, 1, 'lin', 0, 0, ''))
  end
  params:add_separator("snapshot [2]")
  for i = 1,8 do
    params:add_control("s2"..i, "[2] partial "..i, controlspec.new(0, 1, 'lin', 0, 0, ''))
  end
  params:add_separator("snapshot [3]")
  for i = 1,8 do
    params:add_control("s3"..i, "[3] partial "..i, controlspec.new(0, 1, 'lin', 0, 0, ''))
  end
  params:add_separator("snapshot [4]")
  for i = 1,8 do
    params:add_control("s4"..i, "[4] partial "..i, controlspec.new(0, 1, 'lin', 0, 0, ''))
  end
  
  params:set_action("s11", function(x) engine.s11(x) end)
  params:set_action("s12", function(x) engine.s12(x) end)
  params:set_action("s13", function(x) engine.s13(x) end)
  params:set_action("s14", function(x) engine.s14(x) end)
  params:set_action("s15", function(x) engine.s15(x) end)
  params:set_action("s16", function(x) engine.s16(x) end)
  params:set_action("s17", function(x) engine.s17(x) end)
  params:set_action("s18", function(x) engine.s18(x) end)
  
  params:set_action("s21", function(x) engine.s21(x) end)
  params:set_action("s22", function(x) engine.s22(x) end)
  params:set_action("s23", function(x) engine.s23(x) end)
  params:set_action("s24", function(x) engine.s24(x) end)
  params:set_action("s25", function(x) engine.s25(x) end)
  params:set_action("s26", function(x) engine.s26(x) end)
  params:set_action("s27", function(x) engine.s27(x) end)
  params:set_action("s28", function(x) engine.s28(x) end)
  
  params:set_action("s31", function(x) engine.s31(x) end)
  params:set_action("s32", function(x) engine.s32(x) end)
  params:set_action("s33", function(x) engine.s33(x) end)
  params:set_action("s34", function(x) engine.s34(x) end)
  params:set_action("s35", function(x) engine.s35(x) end)
  params:set_action("s36", function(x) engine.s36(x) end)
  params:set_action("s37", function(x) engine.s37(x) end)
  params:set_action("s38", function(x) engine.s38(x) end)
  
  params:set_action("s41", function(x) engine.s41(x) end)
  params:set_action("s42", function(x) engine.s42(x) end)
  params:set_action("s43", function(x) engine.s43(x) end)
  params:set_action("s44", function(x) engine.s44(x) end)
  params:set_action("s45", function(x) engine.s45(x) end)
  params:set_action("s46", function(x) engine.s46(x) end)
  params:set_action("s47", function(x) engine.s47(x) end)
  params:set_action("s48", function(x) engine.s48(x) end)

  params:bang()
end

return Overtones