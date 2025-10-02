// LPDisplayHudMap.sc
// v0.9.7.2 — dB→UI mapping (top/floor/gamma) + preview/print
// MD 2025-10-01
/*
 * 0.9.7.2 clearer local variable names + explanatory comments; NO logic changes (doc-only)
 *
 * Purpose
 * - Map raw linear RMS (0..1) from SendPeakRMS into a UI-friendly 0..1 value using a dB window
 *   (topDb/floorDb) and a perceptual gamma curve. This is optional in the display window:
 *   passing nil for the HUD map means "use raw RMS 0..1".
 *
 * Conventions
 * - *new returns ^super.new.init(...)
 * - Methods return ^this where appropriate; numeric helpers return raw values.
 */

LPDisplayHudMap {
    classvar classVersion = "0.9.7.2";

    // Defaults for headroom window and perceptual curve
    classvar defaultTopDb   = -6.0;
    classvar defaultFloorDb = -60.0;
    classvar defaultGamma   = 1.0;

    // Instance configuration
    var topDb;     // dB at which UI reaches 1.0 (top of meter)
    var floorDb;   // dB at which UI reaches 0.0 (floor of meter)
    var gamma;     // perceptual exponent applied in UI domain

    *initClass {
        ("LPDisplayHudMap v" ++ classVersion ++ " loaded (LivePedalboardDisplay)").postln;
    }

    *new { |topDbArg, floorDbArg, gammaArg|
        // If any parameter is omitted, fall back to defaults above.
        ^super.new.init(
            topDbArg   ?? { defaultTopDb },
            floorDbArg ?? { defaultFloorDb },
            gammaArg   ?? { defaultGamma }
        )
    }

    init { |topDbInit, floorDbInit, gammaInit|
        // Store parameters and keep gamma numerically safe.
        topDb   = topDbInit.asFloat;
        floorDb = floorDbInit.asFloat;
        gamma   = gammaInit.asFloat.max(1e-6);

        // Ensure a valid window (top must be above floor).
        if (topDb <= floorDb) {
            topDb = floorDb + 0.1;
            "LPDisplayHudMap: adjusted top to floor+0.1 dB to keep mapping valid.".postln;
        };
        ^this
    }

    set { |key, value|
        // Small setter to tweak parameters at runtime (e.g., \top -> -9, \gamma -> 1.2).
        var paramKey = key.asSymbol;
        var paramVal = value.asFloat;

        if (paramKey == \top)   { topDb = paramVal };
        if (paramKey == \floor) { floorDb = paramVal };
        if (paramKey == \gamma) { gamma = paramVal.max(1e-6) };

        if (topDb <= floorDb) {
            topDb = floorDb + 0.1;
            "LPDisplayHudMap: adjusted top to floor+0.1 dB.".postln;
        };
        ^this
    }

    mapLinToUi { |linearRms|
        /*
         * Convert a raw linear RMS (0..1) into a UI fraction (0..1):
         * 1) Convert linear amplitude to dBFS.
         * 2) Clip to [floorDb, topDb] window.
         * 3) Normalize to [0,1] and apply gamma.
         */
        var linearClamped      = linearRms.max(1e-9);  // avoid -inf dB
        var amplitudeDb        = linearClamped.ampdb;  // linear -> dBFS
        var topDbLimit         = topDb.asFloat;
        var floorDbLimit       = floorDb.asFloat;
        var gammaLocal         = gamma.asFloat.max(1e-6);
        var uiValue;

        amplitudeDb = amplitudeDb.clip(floorDbLimit, topDbLimit);
        uiValue     = (amplitudeDb - floorDbLimit) / (topDbLimit - floorDbLimit);
        uiValue     = uiValue.pow(gammaLocal);
        ^uiValue.clip(0.0, 1.0)
    }

    preview { |rmsDbValue|
        // Convenience: preview the UI value you’d get for a given RMS dB input.
        var linearFromDb             = rmsDbValue.dbamp.clip(1e-9, 1.0);
        var uiValue                  = this.mapLinToUi(linearFromDb);
        ("HUD UI -> " ++ uiValue.round(0.003) ++ " for " ++ rmsDbValue ++ " dBFS RMS").postln;
        ^uiValue
    }

    print {
        ("HUD: top=" ++ topDb ++ " dB, floor=" ++ floorDb ++ " dB, gamma=" ++ gamma).postln;
        ^this
    }


	/////



	// --- Utility: docs & smoke test (add-only) -----------------------------

*help {
    var lines;
    lines = [
        "LPDisplayHudMap — purpose:",
        "  Map raw linear RMS (0..1) to UI (0..1) using a dB headroom window and gamma.",
        "",
        "Constructor:",
        "  LPDisplayHudMap.new(topDb = -6, floorDb = -60, gamma = 1.0)",
        "",
        "Key methods:",
        "  .set(\\top|\\floor|\\gamma, value)  // tweak mapping",
        "  .mapLinToUi(linearRms)              // 0..1 -> 0..1 UI",
        "  .preview(rmsDb)                     // prints & returns UI for a dB value",
        "  .print()                            // print current mapping",
        "",
        "Tip: In LPDisplayLayoutTestWindow, setHudMap(nil) disables mapping (raw 0..1)."
    ];
    lines.do(_.postln);
    ^this
}

*apihelp {
    var lines;
    lines = [
        "LPDisplayHudMap.apihelp — quick recipes:",
        "  h = LPDisplayHudMap.new(-6, -60, 1.0);",
        "  h.preview(-9);                // see UI at -9 dB RMS",
        "  h.set(\\top, -9).print;        // move top to -9 dB RMS",
        "  h.set(\\gamma, 1.2).print;     // increase perceptual curvature",
        "  // In the layout window:",
        "  //  ~inst.setHudMap(h);         // enable mapping",
        "  //  ~inst.setHudMap(nil);       // disable mapping (raw 0..1)"
    ];
    lines.do(_.postln);
    ^this
}

*test {
    var hud, dbCases, lastUi, passAll;
    hud = this.new(-6, -60, 1.0);
    dbCases = [-60, -30, -18, -12, -9, -6, -3, 0]; // typical points
    lastUi = -1.0;
    passAll = true;

    "LPDisplayHudMap.test — monotonicity & bounds:".postln;
    dbCases.do({ |dbVal|
        var uiVal;
        uiVal = hud.preview(dbVal); // prints & returns
        if (uiVal < lastUi) { passAll = false };
        if ((uiVal < 0.0) or: { uiVal > 1.0 }) { passAll = false };
        lastUi = uiVal;
    });

    if (passAll) {
        "LPDisplayHudMap.test: PASS".postln;
    } {
        "LPDisplayHudMap.test: FAIL (non-monotonic or out-of-bounds)".postln;
    };
    ^passAll
}
}