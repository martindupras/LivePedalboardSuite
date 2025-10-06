// LivePedalboardSystem_WindowManager_FrontHelpers.scd
// v0.1.0
// MD 20251003-1136

/* Purpose/Style:
- Adds a non-destructive 'front or bring-up' helper alongside existing manager.
- Does NOT modify existing helpers; safe to load any time.
- Returns a Window when bringing up; returns nil if fronting was possible but no window.
*/

(
var ensureHelpers;

("Running: LivePedalboardSystem_WindowManager_FrontHelpers.scd").postln;

ensureHelpers = {
    ~lps_frontOrBringUpByPrefix.isNil.if({
        ~lps_frontOrBringUpByPrefix = { |prefix, buildFunc, desiredTitle|
            var win, effectivePrefix;
            effectivePrefix = prefix ?? { ~lps_windowPrefix ?? { "MagicDisplayGUI" } };

            win = ~lps_frontByPrefix.notNil.if({ ~lps_frontByPrefix.(effectivePrefix) }, { nil });
            win.notNil.if({
                // Found one; fronted already, do not recreate
                win
            }, {
                // None found; bring up exactly one via existing manager
                ~lps_bringUpSingleWindow.(effectivePrefix, buildFunc, desiredTitle)
            })
        };
    });
};

ensureHelpers.();
)
