// 02F_HUD_TestContent_StateChoicesIncoming.scd
// v0.1.0
// MD 20250929-1121

/* Purpose
   - Write demo "system state", "choices", and "incoming" text into the existing HUD window.
   - Use the GUI's public API if available:
       showExpectation(String, Int)
       updateTextField(\state | \choices | \lastCommand, String)
   - No server changes; AppClock-only for UI.
   - var-first; lowercase; no server.sync.
*/

(
var g, have, pushStatus, pushChoices, pushIncoming;

g = ~system.notNil.if({ ~system.statusDisplay }, { nil }); // prefer your system GUI if present
have = { |selector| g.notNil and: { g.respondsTo(selector) } };

pushStatus = {
    var text;
    text = "State: serverRunning=true, activeChain=A (demo)\nGroups=(true,true)";
    if(have.(\updateTextField)) { g.updateTextField(\state, text) };
    if(have.(\showExpectation)) { g.showExpectation("System ready — demo text injected", 0) };
};

pushChoices = {
    var txt;
    txt = "Choices:\nFret 7: delay\nFret 9: chorus\nFret 11: reverb\nFret 13: drive";
    if(have.(\updateTextField)) { g.updateTextField(\choices, txt) };
};

pushIncoming = {
    var txt;
    txt = "Incoming: key:a • key:b • key:r (rebuild)";
    if(have.(\updateTextField)) { g.updateTextField(\lastCommand, txt) };
};

// Defer UI calls to AppClock
{
    pushStatus.();
    pushChoices.();
    pushIncoming.();
}.defer;

"[*] 02F: demo HUD text pushed (state/choices/incoming)".postln;
)
