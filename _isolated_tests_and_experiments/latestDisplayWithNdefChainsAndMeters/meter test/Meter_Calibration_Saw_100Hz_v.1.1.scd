// Meter_Calibration_Saw_100Hz.scd
// v1.1 - fixed (no .stretch_), 100 Hz saw @ selectable peak dBFS, RMS meter + 6 dB ticks, 0 dB marked
// MD 20251001

/* Purpose
   - Play a 100 Hz sawtooth at selectable peak amplitudes (dBFS): 0, -6, -12, -18, -20, -60, -128.
   - Show RMS on a LevelIndicator (SendPeakRMS), with a tick strip every 6 dB and 0 dBFS highlighted.
   - Help relate peak dBFS to RMS meter readings (for a saw, RMS ≈ peak - 4.77 dB).

   Mapping
   - Meter UI uses a dB mapping: topDb = 0 dBFS, floorDb = -120 dBFS, gamma = 1.0.
   - Ticks are drawn relative to that mapping, so 0 dB is at the very top, -120 dB at the bottom.

   Style
   - var-first declarations, lowercase method names, no non-local returns (^), GUI updates via defer.
*/

(
var window, paneColor, meter, tickView, labelRms, labelInfo, layout, controlsRow;
var ndefName, oscNameGui, oscNameConsole;

var ampMenu, ampDbChoices, currentAmpDb;
var setAmpDb, ampToRmsDbSaw;

var topDb, floorDb, gamma, mapLinToUi, mapDbToUi, valueFromMsg;

var rebuildNdef, bindOsc, unbindOsc, updateUiLabels;

// ------------- UI bring-up -------------
Window.allWindows.do({ |w| if(w.name == "Meter Calibration Demo", { w.close }) });

window = Window("Meter Calibration Demo", Rect(140, 140, 520, 280))
    .background_(Color.white)
    .front;

paneColor = Color(0.10, 0.30, 0.10);

// ------------- Mapping (linear RMS -> UI) -------------
topDb   = 0.0;     // UI=1 at 0 dBFS RMS
floorDb = -120.0;  // UI=0 at -120 dBFS RMS
gamma   = 1.0;     // 1.0 = linear-in-dB mapping

mapLinToUi = { |lin, top, floor, g|
    var v, vdb, u;
    v   = lin.max(1e-9);        // avoid -inf
    vdb = v.ampdb;              // lin -> dB
    vdb = vdb.clip(floor, top);
    u   = (vdb - floor) / (top - floor);
    u   = u.pow(g);
    u.clip(0.0, 1.0)
};

mapDbToUi = { |db, top, floor, g|
    var vlin, u;
    vlin = db.dbamp.clip(1e-9, 1.0);
    u = mapLinToUi.(vlin, top, floor, g);
    u
};

// ------------- Test source config -------------
ndefName        = \calSaw;
oscNameGui      = \calSaw_toGUI;
oscNameConsole  = \calSaw_console;

ampDbChoices = [0, -6, -12, -18, -20, -60, -128];
currentAmpDb = -12;  // default on bring-up

ampToRmsDbSaw = { |peakDb|
    var peakLin, rmsLin, rmsDb;
    peakLin = peakDb.dbamp;       // peak amplitude (linear)
    rmsLin  = peakLin / 3.sqrt;   // RMS of a symmetric saw ≈ peak / √3
    rmsDb   = rmsLin.ampdb;
    rmsDb
};

rebuildNdef = {
    var freqDefault;
    freqDefault = 100;
    Ndef(ndefName, {
        var amp, freq, sig;
        amp  = \amp.kr(currentAmpDb.dbamp).clip(0.0, 1.0);
        freq = \freq.kr(freqDefault).max(10);
        sig  = Saw.ar([freq, freq]) * amp;   // BL saw, stereo
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsDemo', 1);  // 20 Hz to GUI
        sig
    });
    Ndef(ndefName).play(numChannels: 2);
};

valueFromMsg = { |msg|
    var v, sz;
    v = 0.0;
    if(msg.notNil) {
        sz = msg.size;
        if(sz >= 4) { v = msg[sz - 1].asFloat; };  // take last element (RMS)
    };
    v.clip(0.0, 1.0)
};

// ------------- GUI controls -------------
ampMenu = PopUpMenu()
    .items_(ampDbChoices.collect({ |db| (db.asString ++ " dBFS (peak)") }))
    .background_(Color(0.92, 0.98, 0.92))
    .action_({ |menu|
        var idx, db;
        idx = menu.value;
        db  = ampDbChoices.wrapAt(idx);
        setAmpDb.(db);
    });

labelRms  = StaticText().string_("RMS: (waiting)").align_(\left);
labelInfo = StaticText().string_("info").align_(\left).stringColor_(Color.gray(0.35));

controlsRow = HLayout(
    StaticText().string_("Amplitude:").stringColor_(Color.black),
    ampMenu,
    nil   // let the menu hug left and the row expand
);

// Meter + ticks
meter = LevelIndicator()
    .fixedWidth_(30)
    .warning_(0.50)
    .critical_(0.80);

tickView = UserView()
    .minSize_(Size(64, 180))
    .background_(Color.white);

// Whole layout
layout = VLayout(
    UserView().minSize_(Size(0, 6)),  // spacer
    controlsRow,
    UserView().minSize_(Size(0, 4)),
    HLayout(
        // left: tick strip with heading
        UserView().layout_(VLayout(
            StaticText().string_("dBFS").align_(\center).stringColor_(paneColor),
            tickView
        )).background_(Color.white),
        // right: meter + readouts
        VLayout(
            meter,
            UserView().minSize_(Size(0, 6)),
            labelRms,
            labelInfo
        ).margins_(2)
    ).margins_(8)
).margins_(8);

window.layout = layout;

// ------------- Tick drawing -------------
tickView.drawFunc_({ |v|
    var ctx, w, h, leftPad, rightPad, tickLong, tickShort, db, step, y, u, text;
    var font, zeroColor, tickColor;

    ctx = Pen;
    w = v.bounds.width;
    h = v.bounds.height;

    leftPad   = 4;
    rightPad  = 52;   // reserved label width (visual guide)
    tickLong  = 10;
    tickShort = 6;
    step      = 6;    // tick every 6 dB

    zeroColor = Color(1, 0, 0, 0.35);   // semi-transparent red
    tickColor = Color.gray(0.25);
    font      = Font("Helvetica", 10);

    ctx.use {
        // background
        ctx.color = Color.white;
        ctx.addRect(Rect(0, 0, w, h));
        ctx.fill;

        // 0 dB grid line
        u = mapDbToUi.(0, topDb, floorDb, gamma);
        y = (1 - u) * h;
        ctx.color = zeroColor;
        ctx.width = 1.0;
        ctx.moveTo(Point(leftPad, y));
        ctx.lineTo(Point(w - 2, y));
        ctx.stroke;

        // ticks & labels
        db = 0;
        while({ db >= floorDb }, {
            u = mapDbToUi.(db, topDb, floorDb, gamma);
            y = (1 - u) * h;

            ctx.color = (db == 0).if(zeroColor, tickColor);
            ctx.width = 1.0;

            if((db % 12) == 0) {
                ctx.moveTo(Point(leftPad, y));
                ctx.lineTo(Point(leftPad + tickLong, y));
            }{
                ctx.moveTo(Point(leftPad, y));
                ctx.lineTo(Point(leftPad + tickShort, y));
            };
            ctx.stroke;

            if((db == 0) or: { (db % 12) == 0 }) {
                ctx.font = font;
                ctx.color = Color.black;
                text = db.asString;
                ctx.stringAtPoint(text, Point(leftPad + tickLong + 4, y - 6));
            };

            db = db - step;
        });

        // border
        ctx.color = paneColor;
        ctx.width = 1;
        ctx.addRect(Rect(0.5, 0.5, w - 1, h - 1));
        ctx.stroke;
    };
});

// ------------- OSC + UI updates -------------
bindOsc = {
    var a, b;
    a = OSCdef(oscNameGui);     if(a.notNil) { a.free; };
    b = OSCdef(oscNameConsole); if(b.notNil) { b.free; };

    OSCdef(oscNameGui, { |msg|
        var lin, ui, rmsDb;
        lin   = valueFromMsg.(msg);
        ui    = mapLinToUi.(lin, topDb, floorDb, gamma);
        rmsDb = lin.max(1e-9).ampdb;

        {
            meter.value_(ui);
            labelRms.string_("RMS: " ++ rmsDb.round(0.1) ++ " dBFS    (UI: " ++ ui.round(0.003) ++ ")");
        }.defer;
    }, '/peakrmsDemo');

    // Optional console (decimate if desired)
    OSCdef(oscNameConsole, { |msg|
        // var lin = valueFromMsg.(msg);
        // var rmsDb = lin.max(1e-9).ampdb;
        // ("RMS: " ++ rmsDb.round(0.1) ++ " dBFS").postln;
    }, '/peakrmsDemo');
};

unbindOsc = {
    var a, b;
    a = OSCdef(oscNameGui);     if(a.notNil) { a.free; };
    b = OSCdef(oscNameConsole); if(b.notNil) { b.free; };
};

updateUiLabels = {
    var pred;
    pred = ampToRmsDbSaw.(currentAmpDb);
    {
        labelInfo.string_("peak: " ++ currentAmpDb.asString ++ " dBFS   →   expected RMS (saw): "
            ++ pred.round(0.1) ++ " dBFS   |   top=" ++ topDb ++ " dB, floor=" ++ floorDb);
        tickView.refresh;
    }.defer;
};

// ------------- Control logic -------------
setAmpDb = { |db|
    var idx;
    currentAmpDb = db.asFloat;
    Ndef(ndefName).set(\amp, currentAmpDb.dbamp);
    updateUiLabels.();
    idx = ampDbChoices.indexOf(currentAmpDb).max(0);
    { ampMenu.value_(idx) }.defer;
};

// ------------- Boot + run -------------
Server.default.waitForBoot({
    rebuildNdef.();
    bindOsc.();
    setAmpDb.(currentAmpDb);
});

// ------------- Cleanup -------------
window.onClose = {
    unbindOsc.();
    Ndef(ndefName).stop;
};

window  // -> a Window
)

// -------------------------------------------------------------------------
// One-liners (optional): change amplitude without the menu
// -------------------------------------------------------------------------
//
// (~cal_ampDb = { |db|
// 	var val;
// 	val = db.asFloat;
// 	Ndef(\calSaw).set(\amp, val.dbamp);
// 	("set peak = " ++ val ++ " dBFS").postln;
// };)
//
// ~cal_ampDb.(0);
// ~cal_ampDb.(-6);
// ~cal_ampDb.(-12);
// ~cal_ampDb.(-18);
// ~cal_ampDb.(-20);
// ~cal_ampDb.(-60);
// ~cal_ampDb.(-128);
