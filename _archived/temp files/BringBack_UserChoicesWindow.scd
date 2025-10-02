// BringBack_UserChoicesWindow.scd
// v0.1.0  MD 2025-09-22

/*
Purpose
- Restore the old branch-choices window (UserDisplay) and wire it to CommandManager
  *alongside* MagicDisplayGUI, without changing your classes.

Style
- var-first; lowercase; AppClock-safe; no server.sync.
*/

(
// 1) close any old "user display" windows
Window.allWindows.do({ |w|
    var nm = w.tryPerform(\name);
    if(nm.notNil and: { nm.asString == "user display" }) { w.close };
});

// 2) create the choices window
~userChoices = UserDisplay.new;  // has updateTextField(\state|\queue|\lastCommand|\choices, ...)

// 3) small fan-out adaptor so CommandManager can write to BOTH displays
~displayFan = (
    targets: [ ~system.statusDisplay, ~userChoices ],

    showExpectation: { |self, text, secs = 0|
        self.targets.do({ |t| t.tryPerform(\showExpectation, text, secs) });
    },

    updateTextField: { |self, box, msg|
        self.targets.do({ |t| t.tryPerform(\updateTextField, box, msg) });
    },

    updateStatus: { |self, text|
        self.targets.do({ |t| t.tryPerform(\updateStatus, text) });
    }
);

// 4) inject the fan-out into CommandManager
~system.commandManager.display = ~displayFan;

// 5) initial refresh (shows current state & choices)
~system.commandManager.updateDisplay;
"✅ Choices window wired. Press D2=prog then play notes to see choices update.".postln;
)
