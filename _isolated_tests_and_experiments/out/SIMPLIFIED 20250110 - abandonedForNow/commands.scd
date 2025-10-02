// Switch sources
~setSourceA.(\tone_m6);
~setSourceB.(\bp_sweep);

// Live tweaks
Ndef(\tone_m12).set(\freq, 100);
Ndef(\pulse_tone).set(\rate, 1.2, \freq, 800, \dec, 0.25);
Ndef(\pulse_train).set(\rate, 2.0, \duty, 0.25);
Ndef(\bp_sweep).set(\base, 200, \range, 5000, \rate, 0.07, \rq, 0.15);

// Pane text
~lt_send.(\system, "System ready — quick changes loaded.");
~lt_send.(\diag, "Re-evaluated quick helpers at " ++ Date.getDate.stamp);
~lt_send.(\left,  "Chain A: ~setSourceA.(\\tone_m6)");
~lt_send.(\right, "Chain B: ~setSourceB.(\\bp_sweep)");
