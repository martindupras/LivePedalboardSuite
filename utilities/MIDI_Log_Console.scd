// MIDI_Log_Console.scd
// v0.1.0
// MD 20250922-1420

/*
Purpose
- Log incoming MIDI messages (noteOn, noteOff, CC) to the console with the source device.
- Minimal and non-intrusive: separate MIDIdef keys; no interaction with your handlers.

Style
- var-first; lowercase names; no server.sync; no try/protect; no single-letter vars.
*/

// --- install once (safe to re-evaluate) ---
(
var buildSourceMap, nameForSrc, passesFilter, postLine;

// user-tunable filters (nil = accept all)
~midiLog_srcFilter = ~midiLog_srcFilter ? nil;    // Symbol or Array of Symbols (e.g. [\MD_IAC_to_SC])
~midiLog_chanFilter = ~midiLog_chanFilter ? nil;  // Integer 0..15

// uid -> \Device_Name_Endpoint_Name
~midiLog_sources = ~midiLog_sources ? Dictionary.new;

// rebuild map from MIDIClient.sources
buildSourceMap = {
    var map;
    map = Dictionary.new;
    MIDIClient.init;        // idempotent
    MIDIClient.sources.do { |ep|
        var label;
        label = (ep.device ++ "_" ++ ep.name)
            .replace(" ", "_")
            .replace("-", "_")
            .replace("/", "_")
            .asSymbol;
        map[ep.uid] = label;
    };
    ~midiLog_sources = map;
    "🔎 [MIDI-LOG] source map built (% entries)".format(map.size).postln;
    map.keysValuesDo { |uid, sym| ("  - % -> %".format(uid, sym)).postln };
};

// resolve uid -> label; if unknown, rebuild once
nameForSrc = { |srcID|
    var label;
    label = ~midiLog_sources[srcID];
    if(label.isNil) { buildSourceMap.value; label = ~midiLog_sources[srcID] ?? ("uid:" ++ srcID) };
    ^label
};

// basic filter (source + channel)
passesFilter = { |srcID, chan|
    var srcOk, chOk, srcLabel, setOrVal;
    srcLabel = nameForSrc.value(srcID);
    srcOk = if(~midiLog_srcFilter.isNil) { true } {
        setOrVal = ~midiLog_srcFilter;
        if(setOrVal.isKindOf(Array)) { setOrVal.includes(srcLabel) } { srcLabel == setOrVal }
    };
    chOk = (~midiLog_chanFilter.isNil) or: { chan == ~midiLog_chanFilter };
    ^(srcOk and: chOk)
};

// one-liner formatter
postLine = { |kind, chan, srcID, a, b|
    var srcName, text;
    srcName = nameForSrc.value(srcID);
    text = "[MIDI] %-8s src=%-24s ch=%2d  a=%-4s  b=%-4s"
        .format(kind, srcName, chan, a, b);
    text.postln;
};

// install / replace MIDIdefs
MIDIdef.noteOn(\mdLog_noteOn,   { |vel, num, chan, srcID|
    if(passesFilter.value(srcID, chan)) { postLine.value("noteOn", chan, srcID, num, vel) };
});
MIDIdef.noteOff(\mdLog_noteOff, { |vel, num, chan, srcID|
    if(passesFilter.value(srcID, chan)) { postLine.value("noteOff", chan, srcID, num, vel) };
});
MIDIdef.cc(\mdLog_cc,           { |val, num, chan, srcID|
    if(passesFilter.value(srcID, chan)) { postLine.value("cc", chan, srcID, num, val) };
});

// build initial map and announce
buildSourceMap.value;
"✅ [MIDI-LOG] active. Set ~midiLog_srcFilter or ~midiLog_chanFilter to narrow output. Call ~midiLog_stop.() to remove.".postln;

// global helpers
~midiLog_refresh = { buildSourceMap.value };
~midiLog_stop = {
    ["mdLog_noteOn","mdLog_noteOff","mdLog_cc"].do { |k|
        var key = k.asSymbol;
        var def = MIDIdef(key);
        if(def.notNil) { def.free };
    };
    "🛑 [MIDI-LOG] stopped.".postln;
};
)
