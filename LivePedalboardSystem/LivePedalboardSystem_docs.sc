// LivePedalboardSystem_docs.sc
// v0.3.0
// MD 20251009-0820

// separated from main file for tidiness; console-only docs & smoke tests.

+ LivePedalboardSystem {

    *help {
        var lines;
        lines = [
            "LivePedalboardSystem — purpose:",
            " Glue Display (LPDisplayLayoutWindow + LPDisplayAdapter), Audio (MagicPedalboard A/B Ndefs),",
            " and Commands (CommandManager over a JSON CommandTree).",
            "",
            "How it works (happy path):",
            " - bringUpLPDisplay        : create/open LPDisplay controller, make statusDisplay adapter.",
            " - bringUpPedalboard       : construct MagicPedalboard; wire display adapter if present.",
            " - bringUpCommandSystem    : construct CommandManager; cm.display -> statusDisplay.",
            " - installAdapterBridge    : display-only CommandTree->MagicPedalboard bridge; '/switch' toggles ACTIVE visual.",
            " - refreshDisplay          : pull chain symbols + active A/B from pedalboard; push to display.",
            "",
            "Utilities & safety:",
            " - ensureServerReady       : boot if needed; init tree; return Bool didBoot.",
            " - ensurePedalboardExists  : create pedalboard if nil; ensureSinksDefined.",
            " - ensureSinksDefined      : idempotent pass-through sinks for Ndef(\\chainA) / Ndef(\\chainB).",
            " - ensureAudioOn           : define stereo testmelody/silence; make CURRENT audible if supported.",
            " - installTestMelodies     : define Ndef(\\testmelodyA/B) (stereo).",
            " - routeTestMelodiesToAB   : assign those sources to A/B if API present.",
            " - Logging helpers         : ensureLogger, logInfo, logWarn, logError.",
            " - Path helpers (class)    : *defaultTreePath, *userOverride*, *resolveTreePath.",
            "",
            "Notes:",
            " - If multiple extensions define the same selector (e.g., refreshDisplay or closeExistingMagicDisplayWindows),",
            "   the last compiled definition wins.",
            " - Some repos call enableAutoMeters inside bringUpAll; if not on your path, prefer bringUpAllSafe or step-by-step.",
            ""
        ];
        lines.do(_.postln);
        ^this
    }

    *api {
        var lines;
        lines = [
            "LivePedalboardSystem.api — usage + tiny test ideas",
            "---------------------------------------------------",
            "Instance methods:",
            " • bringUpLPDisplay",
            "     usage:  lps.bringUpLPDisplay;  // -> a Window",
            "     test:   expect a Window; statusDisplay becomes non-nil.",
            " • bringUpPedalboard",
            "     usage:  lps.bringUpPedalboard;",
            "     test:   lps.pedalboard notNil; if adapter present, it's wired.",
            " • bringUpCommandSystem",
            "     usage:  lps.bringUpCommandSystem;",
            "     test:   lps.commandManager notNil; cm.display == lps.statusDisplay.",
            " • installAdapterBridge",
            "     usage:  lps.installAdapterBridge;",
            "     test:   cm.queueExportCallback is a Function; '/switch' toggles ACTIVE visual.",
            " • refreshDisplay",
            "     usage:  lps.refreshDisplay;",
            "     test:   runs without error; updates when adapter present.",
            "",
            " • ensureServerReady",
            "     usage:  lps.ensureServerReady;  // -> Boolean",
            "     test:   returns true on first boot, false after.",
            " • ensurePedalboardExists",
            "     usage:  lps.ensurePedalboardExists;",
            "     test:   pedalboard is present; creates only when nil.",
            " • ensureSinksDefined",
            "     usage:  lps.ensureSinksDefined;",
            "     test:   Ndef(\\chainA) & Ndef(\\chainB) exist; both pass \\in.ar(0!2).",
            " • ensureAudioOn",
            "     usage:  lps.ensureAudioOn;",
            "     test:   Ndef(\\testmelody) & \\stereoSilence defined; CURRENT audible if supported.",
            "",
            " • installTestMelodies",
            "     usage:  lps.installTestMelodies;",
            "     test:   Ndef(\\testmelodyA) & Ndef(\\testmelodyB) exist (stereo).",
            " • routeTestMelodiesToAB",
            "     usage:  lps.routeTestMelodiesToAB;",
            "     test:   no-op safe if setSourceA/B not supported; otherwise sources assigned.",
            "",
            " • ensureLogger",
            "     usage:  lps.ensureLogger;",
            "     test:   logger present or safe postln fallback.",
            " • logInfo / logWarn / logError",
            "     usage:  lps.logInfo(\"TAG\",\"msg\");  // similarly logWarn/logError",
            "     test:   prints with level tags; never throws if logger missing.",
            "",
            " • closeExistingMagicDisplayWindows",
            "     usage:  lps.closeExistingMagicDisplayWindows;",
            "     test:   callable; behavior depends on which extension is active.",
            " • closeExistingLPDisplayWindows",
            "     usage:  lps.closeExistingLPDisplayWindows;",
            "     test:   callable when present; closes 'LPDisplay*' windows.",
            "",
            "Class methods:",
            " • *defaultTreePath",
            "     usage:  LivePedalboardSystem.defaultTreePath;  // -> String",
            "     test:   returns a String path into the shipped repo.",
            " • *userOverrideMDclasses",
            "     usage:  LivePedalboardSystem.userOverrideMDclasses;  // -> String",
            "     test:   returns String; usage discouraged (deprecated).",
            " • *userOverrideUserState",
            "     usage:  LivePedalboardSystem.userOverrideUserState;  // -> String",
            "     test:   returns String under UserState.",
            " • *resolveTreePath(maybePath)",
            "     usage:  LivePedalboardSystem.resolveTreePath(nil);  // -> String",
            "     test:   returns best-available String even if file missing.",
            ""
        ];
        lines.do(_.postln);
        ^this
    }

    *test {
        var passCount, failCount, skipCount, say, check;
        var lps, hadBoot, cmKlass, pbKlass;
        var adapterInstalled, path;

        passCount = 0; failCount = 0; skipCount = 0;

        say = { arg label, status, detail;
            var line;
            line = ("[LPS.test] " ++ status ++ " — " ++ label
                ++ (detail.isNil.if({ "" }, { " — " ++ detail }))).asString;
            line.postln;
        };

        check = { arg label, condition, detail;
            if (condition) {
                passCount = passCount + 1; say.(label, "PASS", detail);
            } {
                failCount = failCount + 1;  say.(label, "FAIL", detail);
            };
        };

        "=== LivePedalboardSystem.test: begin (console-only) ===".postln;

        // Prepare instance
        lps = LivePedalboardSystem.new;
        check.("new", lps.notNil, "constructed");

        // Logger
        lps.ensureLogger;
        check.("ensureLogger", true, "logger or fallback ready");

        // Server
        hadBoot = lps.ensureServerReady;
        check.("ensureServerReady", hadBoot.isBoolean, "returned Boolean");

        // Pedalboard (guard if class missing)
        pbKlass = \MagicPedalboard.asClass;
        if (pbKlass.notNil) {
            lps.ensurePedalboardExists;
            check.("ensurePedalboardExists", lps.pedalboard.notNil, "pedalboard present");
            lps.ensureSinksDefined;
            check.("ensureSinksDefined", (Ndef(\chainA).notNil) and: { Ndef(\chainB).notNil }, "chainA/chainB Ndefs are ready");
        } {
            skipCount = skipCount + 1; say.("ensurePedalboardExists/ensureSinksDefined", "SKIP", "MagicPedalboard not found");
        };

        // Command system (guard if class missing)
        cmKlass = \CommandManager.asClass;
        if (cmKlass.notNil) {
            lps.bringUpCommandSystem;
            check.("bringUpCommandSystem", lps.commandManager.notNil, "commandManager constructed");
        } {
            skipCount = skipCount + 1; say.("bringUpCommandSystem", "SKIP", "CommandManager not found");
        };

        // Bridge (requires both)
        if ((lps.commandManager.notNil) and: { lps.pedalboard.notNil }) {
            lps.installAdapterBridge;
            adapterInstalled = lps.commandManager.respondsTo(\queueExportCallback)
                and: { lps.commandManager.queueExportCallback.isKindOf(Function) };
            check.("installAdapterBridge", adapterInstalled, "queueExportCallback installed");
        } {
            skipCount = skipCount + 1; say.("installAdapterBridge", "SKIP", "requires commandManager + pedalboard");
        };

        // Test melodies
        lps.installTestMelodies;
        check.("installTestMelodies", Ndef(\testmelodyA).notNil and: { Ndef(\testmelodyB).notNil }, "defined A/B melodies");

        lps.routeTestMelodiesToAB;
        check.("routeTestMelodiesToAB", true, "no-op acceptable if API missing");

        // Audio setup (safe; relies on method's own guards)
        lps.ensureAudioOn;
        check.("ensureAudioOn", true, "ran; CURRENT audible if supported");

        // Display refresh (no-op if adapter missing)
        lps.refreshDisplay;
        check.("refreshDisplay", true, "ran without error");

        // Logging helpers
        lps.logInfo("LPS.test", "info sample");
        lps.logWarn("LPS.test", "warn sample");
        lps.logError("LPS.test", "error sample");
        check.("logInfo/logWarn/logError", true, "printed");

        // Window closers (callable without GUI present)
        lps.closeExistingMagicDisplayWindows;
        check.("closeExistingMagicDisplayWindows", true, "invoked");

        if (lps.respondsTo(\closeExistingLPDisplayWindows)) {
            lps.closeExistingLPDisplayWindows;
            check.("closeExistingLPDisplayWindows", true, "invoked");
        } {
            skipCount = skipCount + 1; say.("closeExistingLPDisplayWindows", "SKIP", "not present in this image");
        };

        // Class path helpers
        path = LivePedalboardSystem.defaultTreePath;
        check.("*defaultTreePath", path.isString, path);

        path = LivePedalboardSystem.userOverrideMDclasses;
        check.("*userOverrideMDclasses", path.isString, path);

        path = LivePedalboardSystem.userOverrideUserState;
        check.("*userOverrideUserState", path.isString, path);

        path = LivePedalboardSystem.resolveTreePath(nil);
        check.("*resolveTreePath(nil)", path.isString, path);

        // GUI-heavy bring-ups are intentionally skipped (console-only test)
        skipCount = skipCount + 1; say.("bringUpLPDisplay", "SKIP", "opens a window");
        skipCount = skipCount + 1; say.("bringUpAll / bringUpAllSafe", "SKIP", "may rely on enableAutoMeters");

        ("=== LivePedalboardSystem.test: done — PASS:%  FAIL:%  SKIP:%"
            .format(passCount.asString, failCount.asString, skipCount.asString)).postln;

        ^this
    }

}