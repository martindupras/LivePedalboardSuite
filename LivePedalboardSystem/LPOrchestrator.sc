// LPOrchestrator.sc
// v0
// MD 20251009-1315

LPOrchestrator : Object {
    var <> pedalboard;
    var <> commandManager;
    var <> lpDisplay;
    var <> logger;
	var <> lpLibrary;


	*new {
		^ super.new.init()
	}


	init{
		this.ensureServerReady;
		lpDisplay = LPDisplay.new();  //pass 'this' if want control buttons on lpDisplay
		lpLibrary = LPLibrary.new();
		logger = MDMiniLogger.new();
		commandManager = CommandManager.new(lpDisplay);
		pedalboard = LPPedalboard.new(lpDisplay, lpLibrary);
	}



 cleanUp {   //SH_suggestion
		     // pedalboard.cleanUp
		     // commandManager.cleanUp
		     lpDisplay.closeExistingLPDisplayWindows; // is this defined in lpdisplay?
		     // error manager.cleanUp
		     // maybe shut down server? (note sure order of that one)
	}


    ensureServerReady {
		var myS;
        myS = Server.default;
        if (myS.serverRunning.not) {
            myS.boot;
            myS.waitForBoot; // allowed in your safe-reset pattern
            Server.default.bind({
                myS.initTree;
                myS.defaultGroup.freeAll;
            });
        };
        ^ this
    }





}