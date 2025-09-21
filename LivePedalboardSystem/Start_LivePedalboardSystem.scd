// Start_LivePedalboardSystem.scd
// v0.2.5
// MD 20250921-22:22

// Option A: Pass an explicit path (e.g., alternate tree for testing)
(
    var customPath;
    customPath = Platform.userExtensionDir ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";

    {
        ~system = LivePedalboardSystem.new(customPath);
        ~system.bringUpAll;
    }.defer;  // <-- Function.defer, not thisProcess.defer
)

// Or, to rely on the default
(
    {
        ~system = LivePedalboardSystem.new(nil);  // uses default MagicPedalboardCommandTree.json
        ~system.bringUpAll;
    }.defer;  // <-- Function.defer
)
