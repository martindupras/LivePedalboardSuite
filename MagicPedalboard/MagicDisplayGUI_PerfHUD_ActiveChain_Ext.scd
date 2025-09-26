// MagicDisplayGUI_PerfHUD_ActiveChain_Ext.scd
// v0.1.2
// MD 2025-09-26 15:36 BST

/* Purpose
   Provide a tiny, explicit CURRENT chain flag for the HUD (no pulsing).
   - var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(
~md_currentChain = ~md_currentChain ? \A;

~md_setCurrentChain = { arg chainSymbol;
    var valid;
    valid = (chainSymbol == \A) or: { chainSymbol == \B };
    if(valid) { ~md_currentChain = chainSymbol };
    nil
};

~md_toggleCurrentChain = {
    var now;
    now = ~md_currentChain ? \A;
    ~md_currentChain = (now == \A).if({ \B }, { \A });
    nil
};

~md_isChainAActive = { (~md_currentChain ? \A) == \A };
~md_isChainBActive = { (~md_currentChain ? \A) == \B };
)
