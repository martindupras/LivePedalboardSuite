// FallbackDemo_ManualSequence
// v0.1.3
// MD 20250923

// Purpose:
// - Apply a fixed sequence of canonical commands to MagicPedalboardNew.
// - Uses AppClock for scheduling; no Routine or Task.
// - Follows Martin's SC style: var-first, descriptive names, no server.sync, AppClock-only GUI ops.

(


var canonicalCommands, commandIndex, commandDelay;
var applyCommand, runNextCommand;
var pedalboardRef, bypassState;

canonicalCommands = [
    "/add/delay",
    "/switch",
    "/bypass/delay/on",
    "/bypass/delay/off",
    "/switch"
];

commandIndex = 0;
commandDelay = 0.6;
pedalboardRef = if(~system.notNil) { ~system.pedalboard } { nil };

applyCommand = { |canonicalPath|
    ("[FallbackDemo] apply → " ++ canonicalPath).postln;

    if(~ct_applyOSCPathToMPB.notNil) {
        ~ct_applyOSCPathToMPB.(canonicalPath, pedalboardRef, ~system.statusDisplay);
    } {
        if(pedalboardRef.isNil) {
            ("[FallbackDemo] pedalboard is nil; skipping " ++ canonicalPath).warn;
            nil;
        } {
            if(canonicalPath == "/add/delay") {
                if(pedalboardRef.respondsTo(\add)) {
                    pedalboardRef.add(\delay);
                };
            } {
            if(canonicalPath == "/switch") {
                if(pedalboardRef.respondsTo(\switchChain)) {
                    pedalboardRef.switchChain(0.12);
                };
            } {
            if(canonicalPath == "/bypass/delay/on") {
                bypassState = true;
                if(pedalboardRef.respondsTo(\bypassCurrent)) {
                    pedalboardRef.bypassCurrent(\delay, bypassState);
                };
            } {
            if(canonicalPath == "/bypass/delay/off") {
                bypassState = false;
                if(pedalboardRef.respondsTo(\bypassCurrent)) {
                    pedalboardRef.bypassCurrent(\delay, bypassState);
                };
            } {
                ("[FallbackDemo] unhandled command: " ++ canonicalPath).warn;
            }}}};
        };
    };
};

runNextCommand = {
    if(commandIndex >= canonicalCommands.size) {
        ("[FallbackDemo] done.").postln;
        nil;
    } {
        applyCommand.(canonicalCommands[commandIndex]);
        commandIndex = commandIndex + 1;

        AppClock.sched(commandDelay, {
            runNextCommand.();
            nil;
        });
    };
};

runNextCommand.();
)
