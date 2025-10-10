// LPDisplay.sc
LPDisplay{
	classvar classVersion = "1.0"; // printed at class-load time

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

	var statusDisplay;
	//var commandManager; // wait - why would we neet this? its the other way around

	*initClass {
		("LPDisplayLayoutWindow v" ++ classVersion ++ " loaded (LivePedalboardDisplay)").postln;
	}

	*new { //  aCommandManager
		   | meterHudMapInstance| // recalinh only
	   	//meterHudMapInstance' is an INSTANCE of LPDisplayHudMap (or nil). It is not a name/symbol.
		^super.new.init( //aCommandManager ,
			              meterHudMapInstance)
	}

	*open { |meterHudMapInstance|
		// Convenience: build+open in one call. You can pass nil to use raw meter values without HUD mapping.
		^this.new(meterHudMapInstance).open
	}

	init { | /// aCommandManager
		meterHudMapInstance|
		// Store optional HUD mapping object; nil means "use raw 0..1 RMS for meters".
		var win;
		// var statusDisplay;
		// commandManager = aCommandManager ;
		meterHudMap = meterHudMapInstance;
		paneColor = Color(0.0, 0.35, 0.0);

		// OSCdef keys (names) for GUI and console responders
		oscNameA = \rmsA_toGUI;
		oscNameB = \rmsB_toGUI;
		oscConsoleA = \rmsA_console;
		oscConsoleB = \rmsB_console;

		// NEW: default OFF
		consoleLevelsOn = false;

            this.closeExistingLPDisplayWindows; //should be done by LPDisplay init
            win =this.open; // -> a Window
            // 2. Create an adapter so CommandManager.display calls still work
            statusDisplay = LPDisplayAdapter.new(this);
            // 3. Optional HUD mapping + console quiet
            this.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
            this.setConsoleLevelsOn(false);
            // 4. Front the window and share display with CM (if any)
            AppClock.sched(0.0, { win.front; nil });

		     //what is this doing here? maybe it lives in command manager
          //  if(commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay };
            // 5. No MagicDisplay.ensureMeterDefs anymore (taps live in Ndefs)
             // satisfy your "-> a Window" acceptance

		this.displayTest();

		^this
	}

	// --- Public API -----------------------------------------------------------

	///// CHECK MIGRATION

	   // Canonical closer: match ONLY LPDisplay windows
    closeExistingLPDisplayWindows {
        var windowsToClose, shouldClose;

        shouldClose = { arg w;
            var nameString;
            nameString = (w.name ? "").asString;
            (nameString.beginsWith("LPDisplay")) and: { w.isClosed.not }
        };

        windowsToClose = Window.allWindows.select(shouldClose);

        windowsToClose.do({ arg w;
            var wref;
            wref = w;
            if (wref.notNil and: { wref.isClosed.not }) {
                // avoid recursion if the window has onClose hooks
                wref.onClose = { };
                wref.close;
            };
        });

        ^this
    }




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


	    displayTest {

		this.sendPaneText(\left, 'Hello this is a left');
		this.sendPaneText(\right, 'Hello this is a right');
		this.sendPaneText(\system, 'Hello this is a system');
		this.sendPaneText(\diag, 'Hello this is a diag');
		this.sendPaneText(\choices, 'Hello this is a choices');
		this.sendPaneText(\recv, 'Hello this is a recv');
        ^this
    }

	//---





}