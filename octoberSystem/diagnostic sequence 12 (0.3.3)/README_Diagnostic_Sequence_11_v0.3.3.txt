README_Diagnostic_Sequence_11_v0.3.3.txt
v0.3.3
MD 20251008-2140

====================================================================
Diagnostic Sequence 11 — Working Baseline (LPDisplay + In‑Sink Meters)
====================================================================

Purpose
-------
This guide gives you a *repeatable*, line‑by‑line sequence to prove that:

1) LivePedalboardSystem (LPS) brings up LPDisplay correctly.
2) Chain sinks (\chainA / \chainB) are defined and can be wired to sources.
3) Audio switches deterministically by **playing the sinks** (A ↔ B).
4) Meters in LPDisplay are driven by **in‑sink** SendPeakRMS taps with **fixed IDs**:
   • A → /peakrmsA id **2001**
   • B → /peakrmsB id **2002**

This sequence intentionally **does not** use AutoMeters. It relies solely on in‑sink taps.

What changed (key principles)
-----------------------------
• **No AutoMeters** while testing. They were emitting /peakrms* with variable ids (e.g., 1009, 1011,
  1022, 1023), which confused LPDisplay and our probes. We now remove/avoid them.
• **Meters live inside the sinks** (\chainA/\chainB) using SendPeakRMS with fixed IDs (A=2001,
  B=2002). This makes the UI unambiguous and tracks the audible chain only.
• **Define sinks unconditionally** with `\in.ar(0!2)`. Don’t guard on `.source.isNil`.
• **Wire inputs with `.set(\in, Ndef(...))`** (not `.map`).
• **Never use `Ndef.isPlaying`** to drive control flow. Ndefs are proxies: `.play` monitors to the
  hardware bus; the proxy can be ‘running’ without monitoring.
• **Do not `.play` “silent taps.”** If you need a visual check without audio, prefer a brief audible
  ping or keep taps inside the sinks so meters move only when sinks are audible.
• **No `Server.default.bind`** for `Ndef.play/stop`—those are client‑side controls. Use them directly.

Pre‑requisites
--------------
• Your LPDisplay controller class is available (LPDisplayLayoutWindow).
• LivePedalboardSystem is compiled.
• You’re ok to run a few test Ndefs (testmelodyA/B, srcBleeps, srcPulsedNoise7).

Accepted Results (what ‘working’ looks like)
--------------------------------------------
1) Bring‑up opens one LPDisplay window.
2) Playing **A** produces sound; **only** the **left** (A) meter moves.
3) Switching to **B** produces sound; **only** the **right** (B) meter moves.
4) Remapping A/B inputs changes what you hear on the currently playing sink immediately.

---

How to Run (copy/paste blocks into SC, evaluate **one at a time**)
------------------------------------------------------------------

(0) Boot LPDisplay only + define sources (no mapping, no play)
-------------------------------------------------------------
(
~lpbSystem = ~lpbSystem;
if(~lpbSystem.isNil) {
    ~lpbSystem = LivePedalboardSystem.new;
    ~lpsWindow = ~lpbSystem.bringUpMagicDisplayGUI;  // GUI only (no AutoMeters)
    AppClock.sched(0.0, { ~lpsWindow.front; nil });
};

Ndef(\testmelodyA, {
    var t, e, f, sig;
    t = Impulse.kr(2.2);
    e = Decay2.kr(t, 0.01, 0.30);
    f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
    sig = SinOsc.ar(f) * e * 0.22;
    sig ! 2
});
Ndef(\testmelodyB, {
    var t, e, f, sig;
    t = Impulse.kr(3.1);
    e = Decay2.kr(t, 0.02, 0.18);
    f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
    sig = Pulse.ar(f, 0.35) * e * 0.20;
    sig ! 2
});
Ndef(\srcBleeps, {
    var trig, freq, env, tone, sig;
    trig = Dust.kr(3);
    freq = TExpRand.kr(180, 2800, trig);
    env  = Decay2.kr(trig, 0.005, 0.20);
    tone = SinOsc.ar(freq + TRand.kr(-6, 6, trig));
    sig  = RLPF.ar(tone, (freq * 2).clip(80, 9000), 0.25) * env;
    Pan2.ar(sig, LFNoise1.kr(0.3).range(-0.6, 0.6)) * 0.2
});
Ndef(\srcPulsedNoise7, {
    WhiteNoise.ar(1!2) * SinOsc.kr(7).range(0,1) * 0.2
});
)

(1) Define sinks with in‑sink meters and wire inputs (still silent)
-------------------------------------------------------------------
(
Ndef(\chainA, {
    var x;
    x = \in.ar(0!2);
    SendPeakRMS.kr(x, 24, 3, '/peakrmsA', 2001);
    x
}).ar(2);

Ndef(\chainB, {
    var y;
    y = \in.ar(0!2);
    SendPeakRMS.kr(y, 24, 3, '/peakrmsB', 2002);
    y
}).ar(2);

Ndef(\chainA).set(\in, Ndef(\testmelodyA));
Ndef(\chainB).set(\in, Ndef(\testmelodyB));
Ndef(\chainA).stop; Ndef(\chainB).stop;
)

(2) Play A (expect sound; LPDisplay left/A meter moves)
-------------------------------------------------------
(
Ndef(\chainB).stop;
Ndef(\chainA).play;
)

(3) Switch to B (expect sound; LPDisplay right/B meter moves)
-------------------------------------------------------------
(
Ndef(\chainA).stop;
Ndef(\chainB).play;
)

(4) Live remap examples (run one line at a time)
-----------------------------------------------
// A → pulsed noise
(
Ndef(\chainA).set(\in, Ndef(\srcPulsedNoise7));
)

// B → bleeps
(
Ndef(\chainB).set(\in, Ndef(\srcBleeps));
)

(5) Stop all
------------
(
Ndef(\chainA).stop; Ndef(\chainB).stop;
)

Troubleshooting Appendix
------------------------
• **Meters don’t move** when a sink is audible:
  – Ensure you used (0) + (1) from **this** guide (no AutoMeters); sinks must include in‑sink taps.
  – Confirm IDs: A=2001, B=2002. If LPDisplay filters by ID, wrong IDs will look like ‘no meter.’
  – Optional probes to verify delivery:

(
~probeAcount = 0; ~probeBcount = 0;
~probeAid = IdentitySet.new; ~probeBid = IdentitySet.new;
OSCdef(\probeA, { |msg| ~probeAcount = ~probeAcount + 1; ~probeAid.add(msg[1]) }, '/peakrmsA');
OSCdef(\probeB, { |msg| ~probeBcount = ~probeBcount + 1; ~probeBid.add(msg[1]) }, '/peakrmsB');
)

// After playing A then B, inspect:
(
("A cnt=" ++ (~probeAcount ? 0)).postln;
("B cnt=" ++ (~probeBcount ? 0)).postln;
("A ids=" ++ (~probeAid.asArray.sort.asString)).postln;  // expect [2001]
("B ids=" ++ (~probeBid.asArray.sort.asString)).postln;  // expect [2002]
)

// Cleanup probes:
(
OSCdef(\probeA).free; OSCdef(\probeB).free;
)

• **No sound** but sources play directly:
  – Ensure sinks are defined (block (1)).
  – Ensure you wired inputs with `.set(\in, Ndef(...))`.
  – Play the sink directly: `Ndef(\chainA).play;` or `Ndef(\chainB).play;`.

• **Unexpected console spam**:
  – Disable any old tap proxies and AutoMeters. Stick to in‑sink taps only.


Next Steps: toward a clean BootstrapLPB
--------------------------------------
Goal: A single `BootstrapLPB.scd` that:

1) Brings up the LivePedalboardSystem and opens its own LPDisplay.
2) Ensures sinks exist and meters are in‑sink with fixed IDs.
3) Optionally defines default test sources and wires A/B.
4) Exposes one‑liners to activate A/B.

Plan:
-----
• **Remove AutoMeters** from `bringUpAll` or gate them behind a flag.
  – Short‑term: use `bringUpMagicDisplayGUI` (no AutoMeters) + ensure sinks.
  – Medium‑term: add `bringUpAllSafe` that calls `ensurePedalboardExists` and **does not** enable AutoMeters.

• **Class extension (`.sc`)**: `LivePedalboardSystem-EnsurePedalboard.sc`
  – Methods: `ensurePedalboardExists` (create MagicPedalboard if nil), `ensureSinksDefined` (define \chainA/\chainB),
    `bringUpAllSafe` (wrap bringUpAll, then enforce PB + sinks).

• **BootstrapLPB.scd v0.3.4 (outline)**
(
~lpbSystem = LivePedalboardSystem.new;
~lpsWindow = ~lpbSystem.bringUpMagicDisplayGUI;  // no AutoMeters
AppClock.sched(0.0, { ~lpsWindow.front; nil });

// define sources (optional)
// ... (same as block (0))

// define sinks with in‑sink meters (A=2001, B=2002) and wire inputs
// ... (same as block (1))

// helpers
~activateA = { Ndef(\chainB).stop; Ndef(\chainA).play; };
~activateB = { Ndef(\chainA).stop; Ndef(\chainB).play; };
)

Acceptance Criteria
-------------------
• LPDisplay opens once on bring‑up.
• A plays → left meter moves; B plays → right meter moves.
• Remapping inputs while a sink is playing changes what you hear immediately.

Revision History
----------------
• v0.3.3 — First stable baseline without AutoMeters (in‑sink taps only; fixed IDs).
• v0.3.2 — Removed unnecessary `bind`; clarified sink control; standardized on `.set(\in, ...)`.
• v0.3.1 — Added probes and full reset, discovered AutoMeters interference.
• v0.3.0 — Initial refactor towards in‑sink taps and fixed IDs.

Notes
-----
• These examples avoid `Ndef.isPlaying`, avoid `.play` on “silent taps,” and never guard sink
  definitions or source definitions—they are unconditional for deterministic behavior.