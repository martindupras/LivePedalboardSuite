// MIDI_Input_Tests_20250922.scd
// Run these step by step

// STEP A — canonical bring-up (Option B: default path)
(
{
    if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
    ~system = LivePedalboardSystem.new(nil);   // nil -> class default tree path
    ~system.bringUpAll;
}.defer;
)


// STEP B — Refresh and connect MIDI at the SC level (safe anytime)
(
MIDIClient.restart;     // re-scan devices (good after hot-plug)
MIDIIn.disconnectAll;
MIDIIn.connectAll;

"MIDI Sources:".postln;
MIDIClient.sources.do { |ep| ("  " ++ ep.asString).postln };

"MIDI Destinations:".postln;
MIDIClient.destinations.do { |ep| ("  " ++ ep.asString).postln };
"✅ SC MIDI inputs refreshed & connected.".postln;
)



// STEP C — Inspect manager + the symbol names you can bind
(
var mi;

mi = ~system.commandManager.midiManager;

"—— Device symbols → UIDs (from MIDIInputManager) ——".postln;
mi.listDeviceSymbols;   // prints "Symbol: \NAME  → UID: 1234..."

"—— Pretty device listing ——".postln;
mi.listDevices;         // prints the connected devices it sees
)


// STEP D — Bind nanoKEY2 and IAC "to SC" to handlers
(
var mi = ~system.commandManager.midiManager;

// nanoKEY2 -> FootController (so notes 36/38/40/41 switch idle/prog/queue/send)
mi.bindDevice(\nanoKEY2_KEYBOARD, mi.footControllerHandler);

// IAC "to SC" -> Guitar handler (so notes become frets during PROG mode)
mi.bindDevice(\MD_IAC_to_SC, mi.guitarHandler);

// Show current bindings (srcID → symbol → handler)
"—— Bound handlers (srcID → symbol → handler) ——".postln;
mi.deviceHandlers.keysValuesDo { |srcID, handler|
    var sym = mi.deviceUIDs.keys.detect { |k| mi.deviceUIDs[k] == srcID } ? \UNKNOWN;
    ("  " ++ srcID ++ "  →  " ++ sym ++ "  →  " ++ handler.class.name).postln;
};
)


// Option 1
MIDIdef.trace(true);   // start tracing all MIDI events
// Press a nanoKEY2 key (or send a note to IAC "to SC") — you should see noteOn/off
// When done:
MIDIdef.trace(false);

// Option 2:
// Install once; re-evaluate if you hot-plug (it rebuilds the map)
(
var buildMap;
~midiLog_srcFilter = nil;  // e.g. set to \nanoKEY2_KEYBOARD to filter (optional)
~midiLog_chanFilter = nil; // e.g. set to 1 to filter (optional)
~midiLog_sources   = Dictionary.new;

buildMap = {
    MIDIClient.init;
    ~midiLog_sources = Dictionary.new;
    MIDIClient.sources.do { |ep|
        var sym = (ep.device ++ "_" ++ ep.name)
            .replace(" ","_").replace("-","_").asSymbol;
        ~midiLog_sources[ep.uid] = sym;
    };
    "[MIDI-LOG] map built".postln;
};

buildMap.value;

MIDIdef.noteOn(\mdLog_noteOn, { |vel, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] noteOn  src=%  ch=%  num=%  vel=%"
                .format(sym, chan, num, vel)).postln;
        };
    };
});
MIDIdef.noteOff(\mdLog_noteOff, { |vel, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] noteOff src=%  ch=%  num=%  vel=%"
                .format(sym, chan, num, vel)).postln;
        };
    };
});
MIDIdef.cc(\mdLog_cc, { |val, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] cc     src=%  ch=%  num=%  val=%"
                .format(sym, chan, num, val)).postln;
        };
    };
});

// quick refresh if you hot-plug:
~midiLog_refresh = {
    MIDIClient.restart; MIDIIn.disconnectAll; MIDIIn.connectAll;
    buildMap.value; "[MIDI-LOG] refreshed".postln;
};

// stop logger if needed:
~midiLog_stop = {
    [\mdLog_noteOn,\mdLog_noteOff,\mdLog_cc].do { |k| MIDIdef(k).free };
    "[MIDI-LOG] stopped".postln;
};

"[MIDI-LOG] ACTIVE — press nanoKEY2 or send to IAC".postln;
)

