// LPOrchestrator.sc

// v1.0.4.2 figured out how to get orchestrator to send to display
// v1.0.4.1 trying to correct what gets passed to pedalboard
// v1.0.3 fixed printDiagMessages to actually display in LPDisplay and in console
// v1.0.2 added waitForBoot in init; seems to be working fine
// v1.0.1 removed dubious duplicate
// v1


LPOrchestrator : Object {

	classvar version;

    var <> pedalboard;
    var <> commandManager;
    var <> display;
    var <> logger;
	var <> library;  // LPLibrary

	*initClass {
		var text;
		version = "v1.0.4.2";
		text = "LPOrchestrator " ++ version;
		text.postln;
	}

	*new {
		^ super.new.init()
	}


	init{
		this.ensureServerReady;
		"*** Before server boot (if needed)".postln;
		//AppClock.sched(2, {this.postServerInit; nil});  // return nil to stop rescheduling

		// Seems a betterway to do this AFTER server is up -- working
		 ~serv.waitForBoot( {this.postServerInit;})	
	
	
	}


	postServerInit {
		"*** Afterserver boot".postln;
		display = LPDisplay.new();  //pass 'this' if want control buttons on display
		//<DEBUG>
		// checked: working in v1.0.4.2
		//display.sendPaneText(\left, "REACHED from LPorchestrator.postServerInit");
		//</DEBUG>
		library = LPLibrary.new(); // I THINK THAT'S CORRECT
		logger = MDMiniLogger.new();
		commandManager = CommandManager.new(display);
		pedalboard = LPPedalboard.new(display, library);
	}



 	cleanUp {   //SH_suggestion
		     // pedalboard.cleanUp
		     // commandManager.cleanUp
		     display.closeExistingLPDisplayWindows; // is this defined in lpdisplay?
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

 	check {
        logger.info("This is orchestrator; check.");
		^this
    }

	printDiagMessages { | message |

		// UNCOMMENT FOR DEBUG:
		//postln("Orch printDiagMessages: " ++ message.asString);

		//this.display.sendPaneText(\diag, 'Hello this is a diag'); // wny not printing
		this.display.sendPaneText(\diag, message); // wny not printing
  
		^this
    }

}