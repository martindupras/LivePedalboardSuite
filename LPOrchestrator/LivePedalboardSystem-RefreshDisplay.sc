// LivePedalboardSystem-RefreshDisplay.sc
// v0.1.0
// MD 20251006-1625

+ LivePedalboardSystem {
    refreshDisplay {
        var adapter, aSyms, bSyms, active;
        adapter = this.statusDisplay;  // LPDisplayAdapter
        if(adapter.isNil) { ^this };

        // Try to fetch real chain symbol lists from MagicPedalboard
        aSyms = this.pedalboard.tryPerform(\chainSymbolsA);
        bSyms = this.pedalboard.tryPerform(\chainSymbolsB);
        aSyms = aSyms ? [\chainA, \testmelody];
        bSyms = bSyms ? [\chainB, \stereoSilence];

        adapter.setChains(aSyms, bSyms);

        // Set ACTIVE highlight
        active = this.pedalboard.tryPerform(\currentKey) ? \A; // expect \A or \B
        adapter.setActiveChainVisual(active);

        // Small status line
        adapter.showExpectation("READY", 0);
        ^this
    }
}