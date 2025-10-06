// MIDI_Log_RefreshAndConnect.scd
// v0.1.0
// MD 20250922-1422

/*
Purpose
- If you plugged devices while SC was running, restart the MIDI client,
  reconnect all inputs, and refresh the logger's source map.
- Also clears any logger filters so you see everything.

Style
- var-first; lowercase names; no server.sync; no try/protect; no single-letter vars.
*/

(
var announce;

announce = { |title| ("[MIDI-LOG] " ++ title).postln };

MIDIClient.restart;           // re-scan devices (idempotent & safe)
MIDIIn.disconnectAll;
MIDIIn.connectAll;

~midiLog_srcFilter = nil;     // show all sources
~midiLog_chanFilter = nil;    // show all channels

if(~midiLog_refresh.isKindOf(Function)) {
    ~midiLog_refresh.();      // rebuild the uid->label map used by the logger
    announce.("sources remapped.");
} {
    announce.("note: logger not installed yet; run MIDI_Log_Console.scd first.");
};

// quick device listing
"MIDI Sources:".postln;
MIDIClient.sources.do { |ep| ("  " ++ ep.asString).postln };
"MIDI Destinations:".postln;
MIDIClient.destinations.do { |ep| ("  " ++ ep.asString).postln };
"✅ [MIDI-LOG] refresh complete — play/send something to see messages.".postln;
)
