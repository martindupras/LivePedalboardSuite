// Test_MagicPedalboard_MIDI_Simulation.scd
// v0.1.1
// MD 20250922-18-15

/*
Purpose
- Simulate MIDI input sequences for MagicPedalboard system testing.
- Each test step is labeled and commented with expected GUI/behavior.
- Allows repeatable, device-free testing and can be bundled with the suite.

Style
- var-first; lowercase; AppClock-only; no server.sync; clear comments.
*/

// --- Device UIDs: update these to match your system ---
var nanoUID = 302172822;    // nanoKEY2_KEYBOARD
var iacUID  = 1339807908;   // MD_IAC_to_SC

// --- Helper: fire a sequence of steps ---
~fireMidiSequence = { |steps|
    Routine({
        steps.do { |step|
            var src, chan, note, vel, dur, comment;
            src = step[0]; chan = step[1]; note = step[2];
            vel = step[3]; dur = step[4]; comment = step[5];
            ("[TEST] " ++ comment).postln;
            MIDIIn.doNoteOnAction(src, chan, note, vel);
            (dur ? 0.5).wait;
            MIDIIn.doNoteOffAction(src, chan, note, 0);
            0.1.wait;
        }
    }).play(AppClock);
};

// --- Test Sequence 1: Add Delay and Send ---
~test_add_delay = [
    [nanoUID, 0, 38, 100, 0.5, "Step 1: nanoKEY2 D2 → enter PROG mode"],
    [iacUID,  0, 41, 100, 0.5, "Step 2: IAC string 6 → select /add"],
    [iacUID,  1, 45, 100, 0.5, "Step 3: IAC string 5 → select /delay"],
    [nanoUID, 0, 40, 100, 0.5, "Step 4: nanoKEY2 E2 → queue path"],
    [nanoUID, 0, 41, 100, 0.5, "Step 5: nanoKEY2 F2 → send path"]
];

// --- Test Sequence 2: Switch Chain ---
/*~test_switch_chain = [
    [nanoUID, 0, 38, 100, 0.5, "Step 1: nanoKEY2 D2 → enter PROG mode"],
    [iacUID,  0, 48, 100, 0.5, "Step 2: IAC string 6 → select /switch"],
    [nanoUID, 0, 40, 100, 0.5, "Step 3: nanoKEY2 E2 → queue /switch"],
    [nanoUID, 0, 41, 100, 0.5, "Step 4: nanoKEY2 F2 → send /switch"]
];*/
~test_switch_chain = [
    [nanoUID, 0, 38, 100, 0.5, "Step 1: nanoKEY2 D2 → enter PROG mode"], // enter prog mode
    [iacUID,  0, 43, 100, 0.5, "Step 2: IAC string 6 → select /switch"], // pitch 43 = base 40 + fret 3
    [nanoUID, 0, 40, 100, 0.5, "Step 3: nanoKEY2 E2 → queue /switch"],   // queue
    [nanoUID, 0, 41, 100, 0.5, "Step 4: nanoKEY2 F2 → send /switch"]     // send
];



// --- To run a test sequence ---
~fireMidiSequence.(~test_add_delay);
// ~fireMidiSequence.(~test_switch_chain); // ← uncomment to run this one

// --- Add more sequences below as needed ---
