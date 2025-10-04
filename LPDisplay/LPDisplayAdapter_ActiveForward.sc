// LPDisplayAdapter_ActiveForward.sc
// v0.1.0
// MD 20251004-17:58

/* Purpose
- Forward ACTIVE/NEXT visual calls from the adapter to the LPDisplayLayoutWindow controller.
- Keeps LPDisplayLayoutWindow_ActiveHighlight.sc fully decoupled from AdapterBridge.
*/

+ LPDisplayAdapter {
    setActiveChainVisual { |which|
        if(controller.notNil) {
            controller.tryPerform(\setActiveChainVisual, which);
        };
        ^this
    }
}