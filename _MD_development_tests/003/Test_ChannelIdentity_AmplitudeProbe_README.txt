Test_ChannelIdentity_AmplitudeProbe_README.txt
v0.2.2
MD 20251011-2304

Purpose
-------
This note explains, from first principles, how to build and verify a multi-channel 
signal path in SuperCollider that preserves channel identity and order — with a 
single active channel, no duplication/mixing, and deterministic instrumentation.
It pairs with: Test_ChannelIdentity_AmplitudeProbe.scd

Core principles
---------------
1) Multi-channel = explicit vectors
   • In SuperCollider, returning an Array of audio UGens (e.g., [sig0, sig1, …, sigN-1])
     from a Synth/Ndef defines an N-channel signal. The elements are NOT summed; they
     become distinct channels in order.

2) Force processor width at build time
   • JITLib processors that read input with \in.ar(n) can compile as mono if nothing is
     mapped yet. Use an explicit zero vector to force width immediately:
       inSig = \in.ar(0 ! n);
     This guarantees Ndef(\pass) is N-channel before you connect, avoiding mono adoption.

3) Deterministic connection
   • Use: Ndef(\pass).set(\in, Ndef(\src))
     This creates a single, explicit src → pass path. Do NOT .play the source. Only the
     passthrough .play(vol: 0.0) to compute silently (no hardware output needed).

4) Deterministic probe (SendReply + Amplitude)
   • Avoid guessing UGen-specific OSC payloads. Probe per-channel energy with
     Amplitude.kr and publish a simple vector using SendReply.kr to a known address
     (e.g., "/ampProbe"). On the language side, OSCdef drops [nodeID, replyID] and
     reads the vector directly. This gives a robust AMP print like:
       AMP: [0, 0, 0.07, 0, 0, 0] | aboveThr: [F, F, T, F, F, F] | n=6

5) Trust in-graph Polls for width
   • Hardware output width can differ from your internal bus width; SuperCollider may
     print lines like “wrapped channels from 6 to 1 channels” when attaching to the
     device. That is unrelated to the processor’s internal width. Add a Poll inside the
     Ndef to print the true input width the synth sees:
       Poll.kr(Impulse.kr(1), DC.kr(inSig.size), "pass_in_width");

6) One-hot assertion
   • After a second of probe prints, compute a boolean mask (> threshold) and assert
     that exactly one entry is true at the chosen index.

Minimal implementation pattern
------------------------------
Parameters (example)
• n = 6, activeIndex = 3 (1-based), testFreq = 440, testAmp = 0.1
• probe rate ~10 Hz, threshold ~0.0005 (-66 dB)

Source (single active channel)
• Return an explicit vector of length n with one SinOsc and zeros elsewhere.

Passthrough (identity + probe)
• Read with \in.ar(0 ! n), compute Amplitude.kr per channel, SendReply.kr the vector,
  and Poll the input width once per second.

Connection & run (silent)
• Ndef(\pass).set(\in, Ndef(\src)); Ndef(\pass).play(vol: 0.0)

Expected verification signs
---------------------------
• Poll prints: pass_in_width: n  (this is the authoritative width)
• AMP lines: length n; only the chosen channel is above threshold.
• One-hot PASS: "PASS one-hot: idx=k | amp=[…]"

Common pitfalls (and how this design avoids them)
-------------------------------------------------
• Mono adoption before mapping → Avoided by \in.ar(0 ! n).
• Accidental duplication via multi-channel expansion → Avoided by explicit Array.fill +
  per-index assignment; never rely on implicit expansion for this test.
• Ambiguous routing → Avoided by a single deterministic mapping (set \in to src) and
  ensuring only the passthrough is .play()’d.
• Misleading hardware width prints → Ignore device ‘wrapped channels …’ lines; rely on
  the in-graph Poll for true width.
• Fragile external UGen payloads → Avoided by using SendReply.kr with a simple vector
  shape we define.

Step-by-step recipe (concise)
-----------------------------
1) Reset & params: free \src, \pass; free OSCdef if present; set n, activeIndex, etc.
2) Install OSCdef for "/ampProbe": amp = msg.drop(3).asArray; mask = amp.collect { _ > th };
3) Passthrough Ndef: inSig = \in.ar(0 ! n); amp = Amplitude.kr(inSig); SendReply.kr(trig, 
   "/ampProbe", amp, id); Poll.kr(Impulse.kr(1), DC.kr(inSig.size), "pass_in_width");
4) Source Ndef: Array.fill(n, {{ 0 }}).collect {{ |_, idx| (idx+1==activeIndex).if {{ SinOsc.ar(freq)*amp }}{{ 0 }} }};
5) Connect & run: Ndef(\pass).set(\in, Ndef(\src)); Ndef(\pass).play(vol: 0.0); after ~1 s, 
   assert one-hot on the last mask.

Debugging checklist
-------------------
• If AMP vector length ≠ n: re-run Steps 3→5; confirm you didn’t .play the source; ensure 
  \in.ar(0 ! n) is present in the passthrough.
• If more than one channel is > threshold: re-check the source vector construction; only
  one index should instantiate SinOsc; all others must be exact zeros.
• If no AMP prints: confirm OSCdef address matches SendReply address ("/ampProbe"); ensure
  passthrough is .play()’d (vol 0.0); ensure probe rate > 0.
• If widths print “wrapped …”: ignore; confirm Poll prints pass_in_width: n.

Adapting to 1, 2, or 6 channels
--------------------------------
• Set ~numChannels to 1, 2, or 6; set ~activeIndex to a valid 1-based index.
• Re-run: passthrough (Step 3), source (Step 4), connect/run (Step 5).

Channel sweep (optional extension)
----------------------------------
• Iterate activeIndex = 1..n; rebuild the source each step; wait ~0.5–1.0 s; assert one-hot.
  Keep this separate from the basic single-channel acceptance to keep results deterministic.

Why this approach is dependable (no guesswork)
----------------------------------------------
• The verification is built only from standard SC semantics:
  - Array return → multi-channel signal (no implicit summing).
  - \in.ar(0 ! n) → explicit width at build time, independent of mapping order.
  - SendReply.kr + OSCdef → trivial, known message shape.
  - Poll inside the synth → authoritative internal width, not device width.
• No dependence on external plugin payload conventions; no reliance on device outputs.

Integration tips (LivePedalboardSuite)
--------------------------------------
• Place the .scd in LivePedalboardSuite/utilities.
• Keep the probe OSC address "/ampProbe" namespaced if you run other diagnostics.
• When you build real processors, keep the \in.ar(0 ! n) pattern to lock width and
  avoid surprises when connecting chains.

Acceptance checklist (single run)
---------------------------------
[ ] Poll printed: pass_in_width: n
[ ] AMP vector length = n
[ ] Exactly one channel above threshold at the selected index
[ ] One-hot PASS printed after ~1 s

File pairing
------------
• Script: Test_ChannelIdentity_AmplitudeProbe.scd
• This note: Test_ChannelIdentity_AmplitudeProbe_README.txt
