// LPOrchestrator.sc

// v1.0.1 removed dubious duplicate
// v1


LPOrchestrator : Object {

	classvar version;

    var <> pedalboard;
    var <> commandManager;
    var <> lpDisplay;
    var <> logger;
	var <> lpLibrary;

	*initClass {
		var text;
		version = "v1.0.1";
		text = "LPOrechestrator " ++ version;
		text.postln;
	}

	*new {
		^ super.new.init()
	}


	init{
		this.ensureServerReady;
		"*** Before server boot (if needed)".postln;
		AppClock.sched(2, {this.postServerInit; nil});  // return nil to stop rescheduling
		}


	postServerInit {
		"*** Afterserver boot".postln;
		lpDisplay = LPDisplay.new();  //pass 'this' if want control buttons on lpDisplay
		logger = MDMiniLogger.new();
		commandManager = CommandManager.new(lpDisplay);
		pedalboard = LPPedalboard.new(lpDisplay, lpLibrary);
	}



 cleanUp {   //SH_suggestion
		     // pedalboard.cleanUp
		     // commandManager.cleanUp
		     lpDisplay.closeExistingLPDisplayWindows; // is this defined in lpdisplay?
		     // error manager.cleanUp
		     // maybe shut down server? (not sure order of that one)

		    //  this  method is not used at  present,
		    // but in the way the orchestrator is currently invoked in the stub
		    //  it would not stick around long enough to listen oit for cleanUp messages
		    //  since it  garbage collected immediately after init.
		    // this is easily prevented by invoking  in stub like so: ~orch = LPOrchestrator.new;
	}

	ensureServerReady{
        ~serv = Server.local;
        if (~serv.serverRunning.not) {
            ~serv.boot;
            ~serv.waitForBoot; // allowed in your safe-reset pattern
            ~serv.bind({
                ~serv.initTree;
                ~serv.defaultGroup.freeAll;
            });
        };
        ^ this
    }








}