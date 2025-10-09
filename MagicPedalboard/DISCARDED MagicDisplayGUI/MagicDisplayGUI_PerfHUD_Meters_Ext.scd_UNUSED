// MagicDisplayGUI_PerfHUD_Meters_Ext.scd
// v0.1.0
// MD 2025-09-26 15:05 BST

/* Purpose / Style
   Provide a small dbScale helper and an optional overlay you can attach to the HUD.
   - var-first; descriptive lowercase; AppClock-only; no server.sync; no non-local '^'.
*/

(
~md_dbScale = { arg linAmp, dbMin = -60.0;
    var safeAmp, dbVal, norm;
    safeAmp = (linAmp ? 0.0).max(1e-6);
    dbVal   = safeAmp.ampdb;                      // language-side conversion
    norm    = ((dbVal - dbMin) / (0 - dbMin)).clip(0.0, 1.0);
    norm
};

~md_attachOverlayMeters = {
    var hudWindow, pad, width, height, overlayView;

    hudWindow = Window.allWindows.detect({ arg w;
        var nameString;
        nameString = w.tryPerform(\name);
        nameString.notNil and: { nameString.asString.beginsWith("MagicDisplayGUI") }
    });

    if(hudWindow.isNil) { "⚠️ No MagicDisplayGUI window found.".warn; ^nil };

    pad = 8; width = 12; height = 84;
    overlayView = UserView(hudWindow, Rect(pad, pad, width, height));
    overlayView.background_(Color.clear);

    overlayView.drawFunc_({ arg v;
        var aPair, bPair, aL, aR, bL, bR, aLs, aRs, bLs, bRs, h, halfW;
        aPair = (~md_levelsById.at(2001) ? [0, 0]).collect(_.asFloat);
        bPair = (~md_levelsById.at(2002) ? [0, 0]).collect(_.asFloat);
        aL = aPair[0]; aR = aPair[1]; bL = bPair[0]; bR = bPair[1];

        aLs = ~md_dbScale.(aL, -60.0); aRs = ~md_dbScale.(aR, -60.0);
        bLs = ~md_dbScale.(bL, -60.0); bRs = ~md_dbScale.(bR, -60.0);

        h = v.bounds.height; halfW = v.bounds.width/2;

        // A bottom half
        Pen.fillColor = Color(0.35, 0.9, 0.35);
        Pen.addRect(Rect(0, h/2 - (h/2 * aLs), halfW, (h/2 * aLs))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95);
        Pen.addRect(Rect(halfW, h/2 - (h/2 * aRs), halfW, (h/2 * aRs))); Pen.fill;

        // B top half (lighter)
        Pen.fillColor = Color(0.35, 0.9, 0.35).blend(Color.white, 0.15);
        Pen.addRect(Rect(0, h - (h/2 * bLs), halfW, (h/2 * bLs))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95).blend(Color.white, 0.15);
        Pen.addRect(Rect(halfW, h - (h/2 * bRs), halfW, (h/2 * bRs))); Pen.fill;
    });

    overlayView.visible = true;
    "[HUD] overlay meters attached (top-left; dB-scaled)".postln;
    overlayView
};
)
