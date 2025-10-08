// LPDisplayLayoutWindow.sc
// v0.9.8 removed the testing audio sources and separated OSC meter responders separately
// v0.9.7.4 — Grid window with A/B chains, meters via SendPeakRMS, console prints gated
// MD 2025-10-01
/*
 * 0.9.7.4 add consoleLevelsOn flag (default false) to gate console prints
 * 0.9.7.3 move class-side utility methods (*help, *apihelp, *test) to class scope (compile fix)
 * 0.9.7.2 clearer variable names + explanatory comments; NO logic changes (doc-only)
 * 0.9.7.1 moved makePane out of buildWindow as new method -- cleaner
 * 0.9.7
 - builds a 6‑pane grid GUI with two moving LevelIndicator meters at the top,
 - sets up two signal chains (A and B) built with JITLib Ndef(left) <<> Ndef(right),
 - receives /peakrmsA and /peakrmsB via SendPeakRMS and updates the meters,
 - posts decimated level prints to the console for A/B (~1 Hz),
 - has methods
   open, close
   setSourceA(\sym), setSourceB(\sym) — swap the tail source per chain
   sendPaneText(\diag, "…") — set any pane text
   setHudMap(mapOrNil), printHud — optional meter UI mapping
Works with:
 LPDisplaySigChain — the little wrapper that wires JITLib symbols into a playing chain.
 LPDisplayHudMap — optional linear→UI mapping (dB headroom + gamma) for the meters.
Notes:
 - The optional HUD map (LPDisplayHudMap) maps raw linear RMS (0..1) to UI (0..1) using a dB window
   (top/floor) and gamma. If you pass nil (or later set nil), the meters display raw 0..1 values.
 - SendPeakRMS ‘replyID’ is kept as A=1 and B=2 for continuity with earlier console dumps/tools.
   This preserves compatibility with any previous log parsing that keyed on replyID rather than address.
*/
LPDisplayLayoutWindow {
	classvar classVersion = "0.9.8"; // printed at class-load time



	// --- UI
	var window;
	var paneColor;
	var topLeftText, topLeftMeter;
	var topRightText, topRightMeter;
	var systemText, diagText, choicesText, recvText;

	// --- Chains
	var chainA; // LPDisplaySigChain
	var chainB; // LPDisplaySigChain

	// --- OSC
	var oscNameA, oscNameB, oscConsoleA, oscConsoleB;
	var firstDumpA = true, firstDumpB = true;
	var countA = 0, countB = 0;

	// NEW: console print gate (default OFF)
	var consoleLevelsOn;

	//new
	var paneTitlesByKey;

	// --- Meter mapping (optional)
	// 'meterHudMap' holds an optional LPDisplayHudMap instance. If nil, meters use raw SendPeakRMS RMS (0..1).
	var meterHudMap;

	*initClass {
		("LPDisplayLayoutWindow v" ++ classVersion ++ " loaded (LivePedalboardDisplay)").postln;
	}

	*new { |meterHudMapInstance|
		// 'meterHudMapInstance' is an INSTANCE of LPDisplayHudMap (or nil). It is not a name/symbol.
		^super.new.init(meterHudMapInstance)
	}

	*open { |meterHudMapInstance|
		// Convenience: build+open in one call. You can pass nil to use raw meter values without HUD mapping.
		^this.new(meterHudMapInstance).open
	}

	init { |meterHudMapInstance|
		// Store optional HUD mapping object; nil means "use raw 0..1 RMS for meters".
		meterHudMap = meterHudMapInstance;
		paneColor = Color(0.0, 0.35, 0.0);

		// OSCdef keys (names) for GUI and console responders
		oscNameA = \rmsA_toGUI;
		oscNameB = \rmsB_toGUI;
		oscConsoleA = \rmsA_console;
		oscConsoleB = \rmsB_console;

		// NEW: default OFF
		consoleLevelsOn = false;

		^this
	}

	// --- Public API -----------------------------------------------------------

	open {
		Window.allWindows.do { |existingWindow|
			if (existingWindow.name == "Layout Test") { existingWindow.close }
		}; // ensure only one with this title
		this.buildWindow;

		// Re-enable this if you want the test audio sources
		//this.bootAndBuildGraph;

		// install the meter responders:
		this.installMeterResponders;

		^window // -> a Window
	}

	close {
		// Free any live OSCdefs and stop sinks before closing the window
		var oscGuiDefA = OSCdef(oscNameA);
		var oscGuiDefB = OSCdef(oscNameB);
		var oscConsoleDefA = OSCdef(oscConsoleA);
		var oscConsoleDefB = OSCdef(oscConsoleB);

		if (oscGuiDefA.notNil) { oscGuiDefA.free };
		if (oscGuiDefB.notNil) { oscGuiDefB.free };
		if (oscConsoleDefA.notNil) { oscConsoleDefA.free };
		if (oscConsoleDefB.notNil) { oscConsoleDefB.free };

		if (chainA.notNil) { Ndef(chainA.symbols.first).stop };
		if (chainB.notNil) { Ndef(chainB.symbols.first).stop };

		if (window.notNil) {
			// prevent recursive cleanup: onClose will not call back into close()
			window.onClose = { };
			window.close;
			window = nil;
		};
		^this
	}

	//new
	// Add inside LPDisplayLayoutWindow (instance-side)
	setLeftMeter { arg linear;
		var ui;
		ui = (meterHudMap.notNil).if({ meterHudMap.mapLinToUi(linear) }, { linear });
		if (topLeftMeter.notNil) { topLeftMeter.value_(ui.clip(0.0, 1.0)) };
		^this
	}

	setRightMeter { arg linear;
		var ui;
		ui = (meterHudMap.notNil).if({ meterHudMap.mapLinToUi(linear) }, { linear });
		if (topRightMeter.notNil) { topRightMeter.value_(ui.clip(0.0, 1.0)) };
		^this
	}




	// new
	// install console RMS responders:
/*	installConsoleRespondersIfEnabled {
		var oldA, oldB, extract;
		// Free any previous console responders
		oldA = OSCdef(oscConsoleA); if (oldA.notNil) { oldA.free };
		oldB = OSCdef(oscConsoleB); if (oldB.notNil) { oldB.free };
		if (consoleLevelsOn.not) { ^this }; // nothing to install

		extract = { arg msg;
			var lin = 0.0, n = msg.size;
			if (n >= 4) { lin = msg[n-1].asFloat };
			lin.clip(0.0, 1.0)
		};

		OSCdef(oscConsoleA, { arg msg;
			var v;
			v = extract.value(msg).max(1e-6);
			("A level: " ++ v.ampdb.round(0.1) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
		}, '/peakrmsA');

		OSCdef(oscConsoleB, { arg msg;
			var v;
			v = extract.value(msg).max(1e-6);
			("B level: " ++ v.ampdb.round(0.1) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
		}, '/peakrmsB');

		^this
	}*/

	// setConsoleLevelsOn { arg flag = false;
	// 	consoleLevelsOn = flag.asBoolean;
	// 	this.installConsoleRespondersIfEnabled;
	// 	^this
	// }



/*	setSourceA { |sourceSymbol|
		if (chainA.notNil) {
			chainA.setTailSource(sourceSymbol);
			{
				if (topLeftText.notNil) { topLeftText.string_(chainA.chainToString) };
			}.defer;
		};
		^this
	}*/

/*	setSourceB { |sourceSymbol|
		if (chainB.notNil) {
			chainB.setTailSource(sourceSymbol);
			{
				if (topRightText.notNil) { topRightText.string_(chainB.chainToString) };
			}.defer;
		};
		^this
	}*/

	sendPaneText { |paneKey, aString|
		var paneKeySymbol = paneKey.asSymbol;
		var textString = aString.asString;
		{
			if (paneKeySymbol == \left   and: { topLeftText.notNil  }) { topLeftText.string_(textString) };
			if (paneKeySymbol == \right  and: { topRightText.notNil }) { topRightText.string_(textString) };
			if (paneKeySymbol == \system and: { systemText.notNil   }) { systemText.string_(textString) };
			if (paneKeySymbol == \diag   and: { diagText.notNil     }) { diagText.string_(textString) };
			if (paneKeySymbol == \choices and: { choicesText.notNil }) { choicesText.string_(textString) };
			if (paneKeySymbol == \recv   and: { recvText.notNil     }) { recvText.string_(textString) };
		}.defer;
		^this
	}

	setHudMap { |hudMapOrNil|
		// Plug/unplug the HUD mapping. Pass an LPDisplayHudMap instance to enable perceptual scaling,
		// or nil to use raw RMS values from SendPeakRMS (0..1) directly.
		meterHudMap = hudMapOrNil;
		^this
	}

	printHud {
		if (meterHudMap.notNil) { meterHudMap.print } { "HUD mapping: none (raw 0..1)".postln };
		^this
	}

/*	// NEW: convenience setter to toggle console prints
	setConsoleLevelsOn { |flag = false|
		consoleLevelsOn = flag.asBoolean;
		^this
	}*/

	// --- Internal build steps -------------------------------------------------

    /* Make one labeled pane (internal helper)
     * Returns a UserView that draws a border and hosts a label + provided content.
     */
	makePane { |content, label|
		var labelView, inner, pane, inset;
		labelView = StaticText()
		.string_(label)
		.align_(\center)
		.stringColor_(Color.white)
		.background_(paneColor);
		inner = VLayout(labelView, content);
		pane  = UserView().layout_(inner);
		pane.drawFunc_({ |view|
			inset = 0.5;
			Pen.use {
				Pen.color = paneColor;
				Pen.width = 1;
				Pen.addRect(Rect(
					inset, inset,
					view.bounds.width - (2 * inset),
					view.bounds.height - (2 * inset)
				));
				Pen.stroke;
			};
		});
		^pane
	}

	buildWindow {
		// Pre-create all views explicitly (prevents nil during deferred updates)
		topLeftText  = TextView().editable_(false);
		topLeftMeter = LevelIndicator().fixedWidth_(30);
		topRightText = TextView().editable_(false);
		topRightMeter= LevelIndicator().fixedWidth_(30);
		systemText   = TextView();
		diagText     = TextView();
		choicesText  = TextView();
		recvText     = TextView();

		window = Window("LPDisplay – LayoutWindow", Rect(100, 100, 800, 600))
		.background_(Color.white)
		.front;

		window.layout = GridLayout.rows(
			[
				this.makePane(HLayout(topLeftText,  topLeftMeter),  "Top Left Pane"),
				this.makePane(HLayout(topRightText, topRightMeter), "Top Right Pane")
			],
			[
				this.makePane(VLayout(StaticText().align_(\center), systemText), "System State"),
				this.makePane(VLayout(StaticText().align_(\center), diagText),   "Diagnostic Messages")
			],
			[
				this.makePane(VLayout(StaticText().align_(\center), choicesText), "Choices"),
				this.makePane(VLayout(StaticText().align_(\center), recvText),    "Receiving Commands")
			]
		);

		window.onClose = {
			// Free resources only; do not call window.close here to avoid recursion
			var oscGuiDefA = OSCdef(oscNameA);
			var oscGuiDefB = OSCdef(oscNameB);
			var oscConsoleDefA = OSCdef(oscConsoleA);
			var oscConsoleDefB = OSCdef(oscConsoleB);

			if (oscGuiDefA.notNil) { oscGuiDefA.free };
			if (oscGuiDefB.notNil) { oscGuiDefB.free };
			if (oscConsoleDefA.notNil) { oscConsoleDefA.free };
			if (oscConsoleDefB.notNil) { oscConsoleDefB.free };

			if (chainA.notNil) { Ndef(chainA.symbols.first).stop };
			if (chainB.notNil) { Ndef(chainB.symbols.first).stop };
		};
		^this
	}

	// NEW only OSC reponders for the meters here:

	//---
/*	installMeterResponders {
		// Bind only GUI responders (no audio graph here).
		// Keys stable so re-eval replaces existing.
		OSCdef(\rmsA_toGUI, { arg msg;
			var v = msg.last.asFloat;
			{ this.setLeftMeter(v) }.defer;
		}, '/peakrmsA');

		OSCdef(\rmsB_toGUI, { arg msg;
			var v = msg.last.asFloat;
			{ this.setRightMeter(v) }.defer;
		}, '/peakrmsB');

		^this
	}*/

	installMeterResponders {
		var oldA, oldB;
		oldA = OSCdef(oscNameA); if (oldA.notNil) { oldA.free };
		oldB = OSCdef(oscNameB); if (oldB.notNil) { oldB.free };

		OSCdef(\rmsA_toGUI, { arg msg;
			var v = msg.last.asFloat;
			{ this.setLeftMeter(v) }.defer;
		}, '/peakrmsA');

		OSCdef(\rmsB_toGUI, { arg msg;
			var v = msg.last.asFloat;
			{ this.setRightMeter(v) }.defer;
		}, '/peakrmsB');

		^this
	}
	//---





}