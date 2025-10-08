// LPDisplayLayoutWindow_docs.sc
// v0.9.8

// MD 20251007-1443

// separated from main file for tidiness.


+ LPDisplayLayoutWindow {

	// --- Utility: docs & smoke test (add-only) --------------------------------

	*help {
		var lines;
		lines = [
			"LPDisplayLayoutWindow — purpose:",
			" Build a 6-pane grid window with top-left/right meters driven by SendPeakRMS,",
			" wire two JITLib chains (A/B), print decimated levels, and offer simple control methods.",
			"",
			"Constructor & convenience:",
			" w = LPDisplayLayoutWindow.new( LPDisplayHudMap.new(-6, -60, 1.0) ).open; // -> a Window",
			" w = LPDisplayLayoutWindow.open(nil); // raw meters (no HUD mapping)",
			"",
			"Key methods (instance):",
			" .open -> a Window .close",
			" .setSourceA(\\sym) .setSourceB(\\sym)",
			" .sendPaneText(\\diag, \"...\")",
			" .setHudMap( mapOrNil ) .printHud",
			"",
			"Notes:",
			" - 'replyID' kept as A=1, B=2 for continuity with earlier dumps/tools.",
			" - Pass nil HUD to use raw 0..1 meter values (bypass perceptual mapping)."
		];
		lines.do(_.postln);
		^this
	}

	*apihelp {
		var lines;
		lines = [
			"LPDisplayLayoutWindow.apihelp — useful snippets:",
			" // bring-up (HUD mapped):",
			" ~hud = LPDisplayHudMap.new(-6, -60, 1.0);",
			" ~inst = LPDisplayLayoutWindow.new(~hud);",
			" ~win = ~inst.open; // -> a Window",
			"",
			" // swap sources:",
			" ~inst.setSourceA(\\srcC);",
			" ~inst.setSourceB(\\srcA);",
			"",
			" // pane text:",
			" ~inst.sendPaneText(\\diag, \"Ready @ \" ++ Date.getDate.stamp);",
			"",
			" // HUD on/off:",
			" ~inst.setHudMap(nil);",
			" ~inst.setHudMap(LPDisplayHudMap.new(-9, -60, 1.0)).printHud;",
			"",
			" // console levels on/off:",
			" ~inst.setConsoleLevelsOn(true);   // enable A/B level prints",
			" ~inst.setConsoleLevelsOn(false);  // disable prints (default)",
			"",
			" // class-side one-liner:",
			" LPDisplayLayoutWindow.open(nil); // raw meters"
		];
		lines.do(_.postln);
		^this
	}

	*test {
		var inst, win, passOsc, posted;
		inst = this.new(nil); // raw meters (no HUD)
		win  = inst.open;     // -> a Window
		// After a short delay, check GUI OSCdefs exist, then flip sources & post a diag line.
		AppClock.sched(0.5, {
			passOsc = OSCdef(\rmsA_toGUI).notNil and: { OSCdef(\rmsB_toGUI).notNil };
			inst.setSourceA(\srcC);
			inst.setSourceB(\srcA);
			inst.sendPaneText(\diag, "Self-test OK @ " ++ Date.getDate.stamp);
			AppClock.sched(1.0, {
				inst.close;
				posted = "LPDisplayLayoutWindow.test: " ++ (passOsc.if("PASS", "WARN (GUI OSC not found)"));
				posted.postln;
				nil
			});
			nil
		});
		^win // handy if you want to keep the window reference
	}
}