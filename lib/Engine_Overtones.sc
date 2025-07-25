Engine_Overtones : CroneEngine {

	classvar maxNumVoices = 8;
	var voiceGroup,
	voiceList,
	lastFreq = 0,
	freq = 220,
	attack = 0.01,
	decay = 0.3,
	sustain = 0.7,
	release = 5,
	s11 = 1, s12 = 0, s13 = 0, s14 = 0, s15 = 0, s16 = 0, s17 = 0, s18 = 0,
	s21 = 0, s22 = 0, s23 = 0, s24 = 0, s25 = 0, s26 = 0, s27 = 0, s28 = 0,
	s31 = 0, s32 = 0, s33 = 0, s34 = 0, s35 = 0, s36 = 0, s37 = 0, s38 = 0,
	s41 = 0, s42 = 0, s43 = 0, s44 = 0, s45 = 0, s46 = 0, s47 = 0, s48 = 0,
	morphMixVal = 0,
	morphRate = 4,
	morphStart = 0,
	morphEnd = 3,
	pitchmod = 0,
	pitchrate = 4,
	panwidth = 0,
	panrate = 8,
	gate = 1,
	amp = 0.75;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		voiceGroup = Group.new(context.xg);
		voiceList = List.new();

		// Synth voice
		SynthDef("Overtones", {

			arg freq = 220,
			attack = 0.01,
			decay = 0.3,
			sustain = 0.7,
			release = 5,
			s11 = 1, s12 = 0, s13 = 0, s14 = 0, s15 = 0, s16 = 0, s17 = 0, s18 = 0,
			s21 = 0, s22 = 0, s23 = 1, s24 = 0, s25 = 0, s26 = 0, s27 = 0, s28 = 0,
			s31 = 0, s32 = 0, s33 = 0, s34 = 0, s35 = 1, s36 = 0, s37 = 0, s38 = 0,
			s41 = 0, s42 = 0, s43 = 0, s44 = 0, s45 = 0, s46 = 0, s47 = 1, s48 = 0,
			morphMixVal = 0,
			morphRate = 2,
			morphStart = 0,
			morphEnd = 3,
			pitchmod = 0,
			pitchrate = 4,
			panwidth = 1,
			panrate = 8,
			gate = 1,
			vel = 1,
			amp = 0.75;

			var sinebank = 0,
			oscPresets,
			morphLfo,
			morphRand,
			morphEnv,
			clippedMorph,
			morphMix,
			envelope,
			signal;

			// 8 arrays with 4 elements. The elements are snapshots of a value controlling one oscillators volume.
			oscPresets = [ [ s11, s21, s31, s41 ], [ s12, s22, s32, s42 ], [ s13, s23, s33, s43 ], [ s14, s24, s34, s44 ], [ s15, s25, s35, s45 ], [ s16, s26, s36, s46 ], [ s17, s27, s37, s47 ], [ s18, s28, s38, s48 ] ];

			// 3 types of morphing:
			morphLfo = LFTri.kr( freq: 1 / morphRate, iphase: 3, mul: 1.0 ).range(morphStart, morphEnd );
			morphRand = LFNoise1.kr( 4 /morphRate ).range( morphStart, morphEnd );
			morphEnv = EnvGen.kr( Env.adsr( attackTime: 0.01, decayTime: morphRate, sustainLevel: 0, releaseTime: release ).range( morphEnd, morphStart ), gate: gate, doneAction: 2 );

			// A mix parameter that allows choosing the type of morphing. The mix goes from lfo>random>env:
			morphMix = LinSelectX.kr( morphMixVal, [morphLfo, morphRand, morphEnv] );
			clippedMorph = morphMix.clip( 0, oscPresets.size - 1 );

			8.do{
				arg i;
				var sine;

				//Sinebank with 8 oscillators:
				sine = Pan2.ar(SinOsc.ar( freq: ( freq * ( i + 1 ) ) + LFNoise1.kr(pitchrate).range(pitchmod * -1, pitchmod), mul: LinSelectX.kr( clippedMorph, oscPresets[i] ) ), LFNoise1.kr(panrate).range(panwidth * -1, panwidth * 1 ) );
				sinebank = sinebank + sine;
			};

			// Envelope modulating the main volume:
			envelope = EnvGen.kr(Env.adsr( attackTime: attack, decayTime: decay, sustainLevel: sustain, releaseTime: release ), gate: gate, doneAction: 2 );
			signal = (sinebank * envelope) * vel;
			Out.ar( 0, signal * ( amp * 0.2 ) );

	}).add;

		// Commands

		// noteOn(id, freq, vel)
		this.addCommand(\noteOn, "iff", { arg msg;

			var id = msg[1], freq = msg[2], vel = msg[3];
			var voiceToRemove, newVoice;

			// Remove voice if ID matches or there are too many
			voiceToRemove = voiceList.detect{arg item; item.id == id};
			if(voiceToRemove.isNil && (voiceList.size >= maxNumVoices), {
				voiceToRemove = voiceList.detect{arg v; v.gate == 0};
				if(voiceToRemove.isNil, {
					voiceToRemove = voiceList.last;
				});
			});
			if(voiceToRemove.notNil, {
				voiceToRemove.theSynth.set(\gate, 0);
				voiceToRemove.theSynth.set(\killGate, 0);
				voiceList.remove(voiceToRemove);
			});

			if(lastFreq == 0, {
				lastFreq = freq;
			});

			// Add new voice
			context.server.makeBundle(nil, {
				newVoice = (id: id, theSynth: Synth.new(defName: \Overtones, args: [
				  \freq, freq,
					\attack, attack,
					\decay, decay,
					\sustain, sustain,
					\release, release,
					\s11, s11,
					\s21, s21,
					\s31, s31,
					\s41, s41,
					\s12, s12,
					\s22, s22,
					\s32, s32,
					\s42, s42,
					\s13, s13,
					\s23, s23,
					\s33, s33,
					\s43, s43,
					\s14, s14,
					\s24, s24,
					\s34, s34,
					\s44, s44,
					\s15, s15,
					\s25, s25,
					\s35, s35,
					\s45, s45,
					\s16, s16,
					\s26, s26,
					\s36, s36,
					\s46, s46,
					\s17, s17,
					\s27, s27,
					\s37, s37,
					\s47, s47,
					\s18, s18,
					\s28, s28,
					\s38, s38,
					\s48, s48,
					\morphMixVal, morphMixVal,
					\morphRate, morphRate,
					\morphStart, morphStart,
					\morphEnd, morphEnd,
					\pitchmod, pitchmod,
					\pitchrate, pitchrate,
					\panwidth, panwidth,
					\panrate, panrate,
					\vel, vel.linlin(0, 1, 0.2, 1),
					\amp, amp;

				], target: voiceGroup).onFree({ voiceList.remove(newVoice); }), gate: 1);
				voiceList.addFirst(newVoice);
				lastFreq = freq;
			});
		});

		// noteOff(id)
		this.addCommand(\noteOff, "i", { arg msg;
			var voice = voiceList.detect{arg v; v.id == msg[1]};
			if(voice.notNil, {
				voice.theSynth.set(\gate, 0);
				voice.gate = 0;
			});
		});

		//synth parameters
		this.addCommand(\amp, "f", { arg msg;
			amp = msg[1];
			voiceGroup.set(\amp, amp);
		});

		this.addCommand(\attack, "f", { arg msg;
			attack = msg[1];
			voiceGroup.set(\attack, attack);
		});

		this.addCommand(\decay, "f", { arg msg;
			decay = msg[1];
			voiceGroup.set(\decay, decay);
		});

		this.addCommand(\sustain, "f", { arg msg;
			sustain = msg[1];
			voiceGroup.set(\sustain, sustain);
		});

		this.addCommand(\release, "f", { arg msg;
			release = msg[1];
			voiceGroup.set(\release, release);
		});

		this.addCommand(\morphMixVal, "f", { arg msg;
			morphMixVal = msg[1];
			voiceGroup.set(\morphMixVal, morphMixVal);
		});

		this.addCommand(\morphRate, "f", { arg msg;
			morphRate = msg[1];
			voiceGroup.set(\morphRate, morphRate);
		});

		this.addCommand(\morphStart, "f", { arg msg;
			morphStart = msg[1];
			voiceGroup.set(\morphStart, morphStart);
		});

		this.addCommand(\morphEnd, "f", { arg msg;
			morphEnd = msg[1];
			voiceGroup.set(\morphEnd, morphEnd);
		});

		this.addCommand(\panwidth, "f", { arg msg;
			panwidth = msg[1];
			voiceGroup.set(\panwidth, panwidth);
		});

		this.addCommand(\panrate, "f", { arg msg;
			panrate = msg[1];
			voiceGroup.set(\panrate, panrate);
		});

		this.addCommand(\pitchmod, "f", { arg msg;
			pitchmod = msg[1];
			voiceGroup.set(\pitchmod, pitchmod);
		});

		this.addCommand(\pitchrate, "f", { arg msg;
			pitchrate = msg[1];
			voiceGroup.set(\pitchrate, pitchrate);
		});

		//slot 1
		this.addCommand(\s11, "f", { arg msg;
			s11 = msg[1];
			voiceGroup.set(\s11, s11);
		});
		this.addCommand(\s12, "f", { arg msg;
			s12 = msg[1];
			voiceGroup.set(\s12, s12);
		});
		this.addCommand(\s13, "f", { arg msg;
			s13 = msg[1];
			voiceGroup.set(\s13, s13);
		});
		this.addCommand(\s14, "f", { arg msg;
			s14 = msg[1];
			voiceGroup.set(\s14, s14);
		});
		this.addCommand(\s15, "f", { arg msg;
			s15 = msg[1];
			voiceGroup.set(\s15, s15);
		});
		this.addCommand(\s16, "f", { arg msg;
			s16 = msg[1];
			voiceGroup.set(\s16, s16);
		});
		this.addCommand(\s17, "f", { arg msg;
			s17 = msg[1];
			voiceGroup.set(\s17, s17);
		});
		this.addCommand(\s18, "f", { arg msg;
			s18 = msg[1];
			voiceGroup.set(\s18, s18);
		});

		//slot 2
		this.addCommand(\s21, "f", { arg msg;
			s21 = msg[1];
			voiceGroup.set(\s21, s21);
		});
		this.addCommand(\s22, "f", { arg msg;
			s22 = msg[1];
			voiceGroup.set(\s22, s22);
		});
		this.addCommand(\s23, "f", { arg msg;
			s23 = msg[1];
			voiceGroup.set(\s23, s23);
		});
		this.addCommand(\s24, "f", { arg msg;
			s24 = msg[1];
			voiceGroup.set(\s24, s24);
		});
		this.addCommand(\s25, "f", { arg msg;
			s25 = msg[1];
			voiceGroup.set(\s25, s25);
		});
		this.addCommand(\s26, "f", { arg msg;
			s26 = msg[1];
			voiceGroup.set(\s26, s26);
		});
		this.addCommand(\s27, "f", { arg msg;
			s27 = msg[1];
			voiceGroup.set(\s27, s27);
		});
		this.addCommand(\s28, "f", { arg msg;
			s28 = msg[1];
			voiceGroup.set(\s28, s28);
		});

		//slot 3
		this.addCommand(\s31, "f", { arg msg;
			s31 = msg[1];
			voiceGroup.set(\s31, s31);
		});
		this.addCommand(\s32, "f", { arg msg;
			s32 = msg[1];
			voiceGroup.set(\s32, s32);
		});
		this.addCommand(\s33, "f", { arg msg;
			s33 = msg[1];
			voiceGroup.set(\s33, s33);
		});
		this.addCommand(\s34, "f", { arg msg;
			s34 = msg[1];
			voiceGroup.set(\s34, s34);
		});
		this.addCommand(\s35, "f", { arg msg;
			s35 = msg[1];
			voiceGroup.set(\s35, s35);
		});
		this.addCommand(\s36, "f", { arg msg;
			s36 = msg[1];
			voiceGroup.set(\s36, s36);
		});
		this.addCommand(\s37, "f", { arg msg;
			s37 = msg[1];
			voiceGroup.set(\s37, s37);
		});
		this.addCommand(\s38, "f", { arg msg;
			s38 = msg[1];
			voiceGroup.set(\s38, s38);
		});

		//slot 4
		this.addCommand(\s41, "f", { arg msg;
			s41 = msg[1];
			voiceGroup.set(\s41, s41);
		});
		this.addCommand(\s42, "f", { arg msg;
			s42 = msg[1];
			voiceGroup.set(\s42, s42);
		});
		this.addCommand(\s43, "f", { arg msg;
			s43 = msg[1];
			voiceGroup.set(\s43, s43);
		});
		this.addCommand(\s44, "f", { arg msg;
			s44 = msg[1];
			voiceGroup.set(\s44, s44);
		});
		this.addCommand(\s45, "f", { arg msg;
			s45 = msg[1];
			voiceGroup.set(\s45, s45);
		});
		this.addCommand(\s46, "f", { arg msg;
			s46 = msg[1];
			voiceGroup.set(\s46, s46);
		});
		this.addCommand(\s47, "f", { arg msg;
			s47 = msg[1];
			voiceGroup.set(\s47, s47);
		});
		this.addCommand(\s48, "f", { arg msg;
			s48 = msg[1];
			voiceGroup.set(\s48, s48);
		});

	}

	free {
		voiceGroup.free;
	}
}
