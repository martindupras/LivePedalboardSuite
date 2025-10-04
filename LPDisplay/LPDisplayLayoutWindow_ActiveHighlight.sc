// LPDisplayLayoutWindow_ActiveHighlight.sc
// v0.1.1
// MD 20251004-1718

/*
Purpose
- Add a small API to LPDisplayLayoutWindow to show ACTIVE/NEXT visually.
API
- setActiveChainVisual(\A|\B)          // main entry (colors + titles)
- setTopPaneTitle(\A|\B, string)       // optional helper
- setTopPaneStyle(\A|\B, activeBool)   // optional helper

Style
- var-first; lowercase; AppClock.defer for UI; no server.sync.
*/

+ LPDisplayLayoutWindow {

    activePaneColor { ^Color.fromHexString("#2ecc71") }   // bright green
    nextPaneColor   { ^Color.fromHexString("#2c3e50") }   // dark slate
    brightText      { ^Color.white }
    dimText         { ^Color.fromHexString("#bdc3c7") }

    setTopPaneTitle { |which, str|
        var tgt, st;
        tgt = which.asSymbol;
        st  = (tgt == \A).if({ topLeftText }, { topRightText });
        if(st.notNil) { { st.string_(str.asString) }.defer };
        ^this
    }

    setTopPaneStyle { |which, isActive=true|
        var tgt, st, pane, bg, tc;
        tgt = which.asSymbol;
        st  = (tgt == \A).if({ topLeftText }, { topRightText });
        pane = st.notNil.if({ st.parent }, { nil });
        bg = isActive.if({ this.activePaneColor }, { this.nextPaneColor });
        tc = isActive.if({ this.brightText }, { this.dimText });
        if(pane.notNil and: { pane.respondsTo(\background_) }) { { pane.background_(bg) }.defer };
        if(st.notNil) { { st.stringColor_(tc) }.defer };
        ^this
    }

    summaryAfterDash { |labelObj|
        var s, idx;
        s = (labelObj ? "").asString;
        idx = s.find("—");
        ^(idx.notNil).if({ " — " ++ s.copyRange(idx+1, s.size-1).trim }, { "" })
    }

    setActiveChainVisual { |which=\A|
        var activeIsA, summaryA, summaryB;
        activeIsA = (which.asSymbol == \A);
        summaryA = this.summaryAfterDash(topLeftText);
        summaryB = this.summaryAfterDash(topRightText);
        this.setTopPaneStyle(\A, activeIsA);
        this.setTopPaneStyle(\B, activeIsA.not);
        this.setTopPaneTitle(\A, (activeIsA.if("Chain A ACTIVE","Chain A NEXT") ++ summaryA));
        this.setTopPaneTitle(\B, (activeIsA.if("Chain B NEXT","Chain B ACTIVE") ++ summaryB));
        ^this
    }
}
