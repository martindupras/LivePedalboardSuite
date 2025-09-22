// Start_LivePedalboardSystem.scd
// v0.2.6
// MD 2025-09-22 11:42 BST

/*
Purpose
- Canonical entry to construct LivePedalboardSystem and call bringUpAll.
- Evaluate ONE of the two blocks below (explicit vs. default).

Style
- var-first; Function.defer (not thisProcess.defer); no server.sync; AppClock-safe.
*/

// --- Option A: explicit path (uncomment to use) ---
//(
//     var customPath;
//     customPath = Platform.userExtensionDir
//         ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
//
//     {
//         // optional: stop a previous instance cleanly
//         if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
//         ~system = LivePedalboardSystem.new(customPath);
//         ~system.bringUpAll;
//     }.defer;  // <-- Function.defer
//)

// --- Option B: rely on class default (preferred day to day)
(
    {
        // optional: stop a previous instance cleanly
        if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
        ~system = LivePedalboardSystem.new(nil);  // nil → class default in LivePedalboardSuite
        ~system.bringUpAll;
    }.defer;  // <-- Function.defer
)
