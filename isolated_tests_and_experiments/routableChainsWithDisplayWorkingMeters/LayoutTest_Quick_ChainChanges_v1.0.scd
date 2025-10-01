// LayoutTest_Quick_ChainChanges.scd
// v1.0 - one-liners to change the running Layout Test chains (no new window)
// MD 20250930
/* Purpose
   - Provide single-line commands to manipulate the *existing* Layout Test session:
     • swap sources with the exported helpers (~setSourceA / ~setSourceB)
     • clear processors by reconnecting sinks directly to sources
     • optionally insert simple processors inline (define + connect) without touching the GUI setup
   - Meters and audio keep running; GUI labels will update only when using ~setSourceA/~setSourceB.

   Style
   - var-first inside any inline Ndef functions
   - Ndef(left) <<> Ndef(right)
   - sinks/processors read \in.ar(2)
   - no server.sync, no ^ non-local returns
*/

// -------------------------------------------------------------
// A) Swap sources (updates the chain labels in the Layout Test GUI)
// -------------------------------------------------------------

~setSourceA.(\srcA);
~setSourceA.(\srcB);
~setSourceA.(\srcC);

~setSourceB.(\srcA);
~setSourceB.(\srcB);
~setSourceB.(\srcC);

// -------------------------------------------------------------
// B) Clear/force direct wiring (does NOT change the GUI text labels)
//    - Reconnect sinks directly to specific sources
//    - Safe to use anytime; it overrides any intermediate processors
// -------------------------------------------------------------

(Ndef(\outA) <<> Ndef(\srcA); Ndef(\outA).play(numChannels: 2););
(Ndef(\outA) <<> Ndef(\srcB); Ndef(\outA).play(numChannels: 2););
(Ndef(\outA) <<> Ndef(\srcC); Ndef(\outA).play(numChannels: 2););

(Ndef(\outB) <<> Ndef(\srcA); Ndef(\outB).play(numChannels: 2););
(Ndef(\outB) <<> Ndef(\srcB); Ndef(\outB).play(numChannels: 2););
(Ndef(\outB) <<> Ndef(\srcC); Ndef(\outB).play(numChannels: 2););

// -------------------------------------------------------------
// C) Quick inline processors (define if needed, then connect)
//    - These are one-liners that (re)define a processor and rebuild the A/B chain explicitly.
//    - GUI text won’t reflect processors; meters will show the result.
// -------------------------------------------------------------

// A: outA <- p_gain <- srcA
(Ndef(\p_gain, { var inSig, amp; inSig = \in.ar(2); amp = \amp.kr(0.8).clip(0.0, 2.0); inSig * amp }); Ndef(\outA) <<> Ndef(\p_gain); Ndef(\p_gain) <<> Ndef(\srcA); Ndef(\outA).play(numChannels:2););

// A: outA <- p_tanh <- srcB
(Ndef(\p_tanh, { var inSig, drive; inSig = \in.ar(2); drive = \drive.kr(1.2).clip(0.1, 5.0); (inSig * drive).tanh * 0.9 }); Ndef(\outA) <<> Ndef(\p_tanh); Ndef(\p_tanh) <<> Ndef(\srcB); Ndef(\outA).play(numChannels:2););

// A: outA <- p_delay <- srcC
(Ndef(\p_delay, { var inSig, time, fb; inSig = \in.ar(2); time = \time.kr(0.25).clip(0.0, 2.0); fb = \fb.kr(0.3).clip(0.0, 0.95); (DelayC.ar(inSig, 2.0, time) * 0.7) + (inSig * (1.0 - fb)) }); Ndef(\outA) <<> Ndef(\p_delay); Ndef(\p_delay) <<> Ndef(\srcC); Ndef(\outA).play(numChannels:2););

// B: outB <- p_gain <- p_tanh <- srcA
(Ndef(\p_gain, { var inSig, amp; inSig = \in.ar(2); amp = \amp.kr(0.9).clip(0.0, 2.0); inSig * amp }); Ndef(\p_tanh, { var inSig, drive; inSig = \in.ar(2); drive = \drive.kr(1.3).clip(0.1, 5.0); (inSig * drive).tanh * 0.9 }); Ndef(\outB) <<> Ndef(\p_gain); Ndef(\p_gain) <<> Ndef(\p_tanh); Ndef(\p_tanh) <<> Ndef(\srcA); Ndef(\outB).play(numChannels:2););

// B: outB <- p_delay <- p_gain <- srcB
(Ndef(\p_delay, { var inSig, time, fb; inSig = \in.ar(2); time = \time.kr(0.33).clip(0.0, 2.0); fb = \fb.kr(0.25).clip(0.0, 0.95); (DelayC.ar(inSig, 2.0, time) * 0.7) + (inSig * (1.0 - fb)) }); Ndef(\p_gain, { var inSig, amp; inSig = \in.ar(2); amp = \amp.kr(0.7).clip(0.0, 2.0); inSig * amp }); Ndef(\outB) <<> Ndef(\p_delay); Ndef(\p_delay) <<> Ndef(\p_gain); Ndef(\p_gain) <<> Ndef(\srcB); Ndef(\outB).play(numChannels:2););

// -------------------------------------------------------------
// D) Adjust processor params live (after you’ve connected them)
// -------------------------------------------------------------

Ndef(\p_gain).set(\amp, 1.2);
Ndef(\p_gain).set(\amp, 0.6);

Ndef(\p_tanh).set(\drive, 0.9);
Ndef(\p_tanh).set(\drive, 2.0);

Ndef(\p_delay).set(\time, 0.125, \fb, 0.35);
Ndef(\p_delay).set(\time, 0.50,  \fb, 0.20);

// -------------------------------------------------------------
// E) Quick source variations (optional redefinitions)
//    - You can re-evaluate these to change how a source sounds
// -------------------------------------------------------------

Ndef(\srcA, { PinkNoise.ar(0.05 ! 2) });
Ndef(\srcB, { SinOsc.ar([220, 221], mul: 0.15) });
Ndef(\srcC, { LFSaw.ar([123, 129]).tanh * 0.20 });

// -------------------------------------------------------------
// F) Safety / recover (if you get lost, go direct and re-play)
// -------------------------------------------------------------

(Ndef(\outA) <<> Ndef(\srcA); Ndef(\outA).play(numChannels:2););
(Ndef(\outB) <<> Ndef(\srcB); Ndef(\outB).play(numChannels:2););
