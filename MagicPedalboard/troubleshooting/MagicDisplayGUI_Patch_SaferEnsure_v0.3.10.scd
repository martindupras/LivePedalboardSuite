// MagicDisplayGUI_Patch_SaferEnsure_v0.3.10.scd
// v0.3.10
// MD timestamp: 2025-09-25

/* Purpose
   - Replace ~md_ensureRouting with a NON-DESTRUCTIVE version:
     * does NOT call s.defaultGroup.freeAll
     * only creates/repairs OUR groups/bus/probes if missing or not playing
   - Keeps your Ndefs and any other nodes intact.

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase names; known-good SC syntax.
*/

(
var safeEnsure;

("MagicDisplayGUI_Patch_SaferEnsure_v0.3.10.scd").postln;

safeEnsure = {
    var ok, needBus, needGroups, needRelay, needProbe, defaultGroup;

    ok = true;

    if (s.serverRunning.not) {
        s.boot;
        s.waitForBoot({
            var ok2;
            ok2 = true;
            s.initTree;
            ok2;
        });
    };

    defaultGroup = s.defaultGroup;

    // bus
    needBus = (~md_mixBus.isNil);

    // groups
    needGroups = (
        ~md_srcGroup.isNil or: { ~md_meterGroup.isNil } or: { ~md_outGroup.isNil } or: {
            (~md_srcGroup.notNil and: { ~md_srcGroup.isPlaying.not })
            or: (~md_meterGroup.notNil and: { ~md_meterGroup.isPlaying.not })
            or: (~md_outGroup.notNil and: { ~md_outGroup.isPlaying.not })
        }
    );

    // relay + default probe
    needRelay = (~md_toHardware.isNil or: { ~md_toHardware.isPlaying.not });
    needProbe = (~md_probe.isNil or: { ~md_probe.isPlaying.not });

    s.bind({
        // bus
        if (needBus) {
            if (~md_mixBus.notNil) { ~md_mixBus.free; ~md_mixBus = nil; };
            ~md_mixBus = Bus.audio(s, 2);
        };

        // groups in strict order
        if (needGroups) {
            if (~md_outGroup.notNil) { ~md_outGroup.free; ~md_outGroup = nil; };
            if (~md_meterGroup.notNil) { ~md_meterGroup.free; ~md_meterGroup = nil; };
            if (~md_srcGroup.notNil) { ~md_srcGroup.free; ~md_srcGroup = nil; };

            ~md_srcGroup = Group.head(defaultGroup);
            ~md_meterGroup = Group.after(~md_srcGroup);
            ~md_outGroup = Group.after(~md_meterGroup);

            // force re-create relay/probe after new groups
            needRelay = true;
            needProbe = true;
        };

        if (needRelay) {
            if (~md_toHardware.notNil) { ~md_toHardware.free; ~md_toHardware = nil; };
            ~md_toHardware = Synth.tail(~md_outGroup, \md_toHardware_2ch, [\inBus, ~md_mixBus.index]);
        };

        if (needProbe) {
            if (~md_probe.notNil) { ~md_probe.free; ~md_probe = nil; };
            ~md_probe = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, ~md_mixBus.index, \replyID, 1001]);
        };
    });

    ok;
};

// replace the old ensure with the safe one
~md_ensureRouting = {
    var ok;
    ok = true;
    safeEnsure.value;
    ok;
};

"Patched ~md_ensureRouting to be non-destructive.".postln;
)
