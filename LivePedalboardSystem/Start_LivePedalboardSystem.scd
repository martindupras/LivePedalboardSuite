// Start_LivePedalboardSystem.scd
// v0.2.7
// MD 20250923-1331

/*
Purpose
- Canonical entry to construct LivePedalboardSystem and call bringUpAll.
- Install the queue→adapter bridge so SHORT canonical commands are applied via the adapter.

Style
- var-first; Function.defer (not thisProcess.defer); no server.sync; AppClock-safe.
*/

// --- Option A: explicit path (uncomment to use) ---
//(
//     {
//         var customPath;
//         if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
//         customPath = Platform.userExtensionDir
//             ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
//         ~system = LivePedalboardSystem.new(customPath);
//         ~system.bringUpAll;
//         ~system.installAdapterBridge;   // ← ONE LINE
//     }.defer;
//)

// --- Option B: rely on class default (preferred day to day)
(
    {
        var systemRef;
        if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
        systemRef = LivePedalboardSystem.new(nil);  // nil → class default in LivePedalboardSuite
        ~system = systemRef;
        ~system.bringUpAll;

        //New: install the queue→adapter bridge (SHORT canonicals → MPB)
        ~system.installAdapterBridge;
    }.defer;
)

