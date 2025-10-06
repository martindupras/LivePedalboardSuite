//MIDI_Input_Tests2_20250922.scd

// 0) Bring-up (Option B: default path)
(
{
    if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
    ~system = LivePedalboardSystem.new(nil);
    ~system.bringUpAll;
}.defer;
)


// 1) Refresh MIDI in SC and connect all sources
(
MIDIClient.restart;     // re-scan devices (safe after hot-plugging)
MIDIIn.disconnectAll;
MIDIIn.connectAll;

"MIDI Sources:".postln;
MIDIClient.sources.do { |ep| ("  " ++ ep.asString).postln };

"MIDI Destinations:".postln;
MIDIClient.destinations.do { |ep| ("  " ++ ep.asString).postln };
"✅ SC MIDI inputs refreshed & connected.".postln;
)


// 2) See the symbols your app uses and their UIDs
(
var mi = ~system.commandManager.midiManager;
"—— Device symbols → UIDs (from MIDIInputManager) ——".postln;
mi.listDeviceSymbols;
"—— Pretty device listing ——".postln;
mi.listDevices;
)


// 3) Bind nanoKEY2 -> FootController; IAC 'to SC' -> Guitar
(
var mi = ~system.commandManager.midiManager;
mi.bindDevice(\nanoKEY2_KEYBOARD, mi.footControllerHandler);
mi.bindDevice(\MD_IAC_to_SC,      mi.guitarHandler);

// Print bound table (srcID → symbol → handler)
"—— Bound handlers (srcID → symbol → handler) ——".postln;
mi.deviceHandlers.keysValuesDo { |srcID, handler|
    var sym = mi.deviceUIDs.keys.detect({ |k| mi.deviceUIDs[k] == srcID }) ? \UNKNOWN;
    ("  " ++ srcID ++ "  →  " ++ sym ++ "  →  " ++ handler.class.name).postln;
};
)

MIDIdef.trace(true);   // enable global trace
// press keys on nanoKEY2 or send notes to IAC "to SC"
MIDIdef.trace(false);

// 4B) Install raw taps (noteOn/noteOff/cc)
(
var mkLabel, fns;

mkLabel = { |src|
    var ep = MIDIClient.sources.detect({ |e| e.uid == src });
    if(ep.notNil) { (ep.device ++ "_" ++ ep.name).replace(" ","_").replace("-","_") } { "uid:" ++ src }
};

~midiTap_remove.(); // remove any previous tap safely (defined below)

// keep references so we can remove cleanly
~midiTap_fns = IdentityDictionary[
    \noteOn  -> MIDIIn.addFuncTo(\noteOn,  { |src, chan, num, vel| ("[RAW] noteOn  src=%  ch=%  num=%  vel=%".format(mkLabel.(src), chan, num, vel)).postln; }),
    \noteOff -> MIDIIn.addFuncTo(\noteOff, { |src, chan, num, vel| ("[RAW] noteOff src=%  ch=%  num=%  vel=%".format(mkLabel.(src), chan, num, vel)).postln; }),
    \control -> MIDIIn.addFuncTo(\control, { |src, chan, num, val| ("[RAW] cc     src=%  ch=%  num=%  val=%".format(mkLabel.(src), chan, num, val)).postln; })
];

~midiTap_remove = {
    if(~midiTap_fns.notNil) {
        ~midiTap_fns.keysValuesDo { |k, fn| if(fn.notNil) { MIDIIn.removeFuncFrom(k, fn) } };
        ~midiTap_fns = nil;
        "[RAW] taps removed".postln;
    } {
        // noop
    };
};

"[RAW] taps installed — press nanoKEY2 or send to IAC".postln;
)


// 4C) Minimal logger (noteOn/off & CC), with map refresh helper
(
var buildMap;
~midiLog_srcFilter = nil;
~midiLog_chanFilter = nil;
~midiLog_sources   = Dictionary.new;

buildMap = {
    MIDIClient.init;
    ~midiLog_sources = Dictionary.new;
    MIDIClient.sources.do { |ep|
        var sym = (ep.device ++ "_" ++ ep.name).replace(" ","_").replace("-","_").asSymbol;
        ~midiLog_sources[ep.uid] = sym;
    };
    "[MIDI-LOG] map built".postln;
};

~midiLog_refresh = {
    MIDIClient.restart; MIDIIn.disconnectAll; MIDIIn.connectAll;
    buildMap.value; "[MIDI-LOG] refreshed".postln;
};

~midiLog_stop = {
    [\mdLog_noteOn,\mdLog_noteOff,\mdLog_cc].do { |k|
        var def = MIDIdef(k);
        if(def.notNil) { def.free };
    };
    "[MIDI-LOG] stopped".postln;
};

buildMap.value;

MIDIdef.noteOn(\mdLog_noteOn, { |vel, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] noteOn  src=%  ch=%  num=%  vel=%".format(sym, chan, num, vel)).postln;
        };
    };
});
MIDIdef.noteOff(\mdLog_noteOff, { |vel, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] noteOff src=%  ch=%  num=%  vel=%".format(sym, chan, num, vel)).postln;
        };
    };
});
MIDIdef.cc(\mdLog_cc, { |val, num, chan, src|
    var sym = ~midiLog_sources[src] ? ("uid:" ++ src);
    if(~midiLog_srcFilter.isNil or: { sym == ~midiLog_srcFilter }) {
        if(~midiLog_chanFilter.isNil or: { chan == ~midiLog_chanFilter }) {
            ("[MIDI] cc     src=%  ch=%  num=%  val=%".format(sym, chan, num, val)).postln;
        };
    };
});

"[MIDI-LOG] ACTIVE — press nanoKEY2 or send to IAC".postln;
)
