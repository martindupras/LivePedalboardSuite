// MagicDisplayGUI_NewPath_Step1_Patch_OSC_ReceiverFix.scd
// v0.2.2
// MD timestamp: 2025-09-25

/* Purpose
   - Reinstall the /reply receiver for level updates with explicit recvPort.
   - Keep updating ~levels and record a heartbeat time (~md_lastLevelAt) for GUI status.
   - Non-invasive: does not touch groups/synths/busses.

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase variables; known-good SC syntax.
*/

(
var reinstallReceiver;

reinstallReceiver = {
    var existing;

    existing = OSCdef(\md_levels);
    if (existing.notNil) {
        existing.free;
    };

    ~levels = [0.0, 0.0];
    ~md_lastLevelAt = Main.elapsedTime;

    OSCdef(
        \md_levels,
        { |msg, time, addr, recvPort|
            var tag, count, i, outArray;

            tag = msg[2];
            count = 0;
            i = 0;
            outArray = nil;

            if (tag == "/md/levels") {
                count = msg.size - 3;
                outArray = Array.newClear(count);
                i = 0;
                while { i < count } {
                    outArray[i] = msg[3 + i].asFloat.clip(0.0, 1.0);
                    i = i + 1;
                };
                ~levels = outArray;
                ~md_lastLevelAt = Main.elapsedTime;
            };
        },
        '/reply',
        recvPort: NetAddr.langPort  // explicit
    );

    true;
};

"Reinstalling /reply receiver...".postln;
reinstallReceiver.value;
)
