// Meter_Calibration_Saw_100Hz.scd
// v1.2 - remove .stretch_ (unsupported), align tick strip & meter; 6 dB ticks; 0 dBFS marked
// MD 20251001

/* Purpose
   - Single Ndef playing a 100 Hz saw at selectable peak dBFS: 0, -6, -12, -18, -20, -60, -128.
   - LevelIndicator shows RMS via SendPeakRMS; a tick strip shows 6 dB marks with 0 dBFS highlighted.
   - Clean layout: tick strip and meter share identical height and align perfectly.

   Style
   - var-first declarations in every block/function
   - lowercase method names, descriptive identifiers
   - no non-local returns (^)
   - GUI updates via AppClock.defer
*/

(
var window, paneColor, meter, tickView, labelRms, labelInfo, layout, controlsRow;
var ndefName, oscNameGui, oscNameConsole;

var ampMenu, ampDbChoices, currentAmpDb;
var setAmpDb, ampToRmsDbSaw;

var topDb, floorDb, gamma, mapLinToUi, mapDbToUi, valueFromMsg;

var rebuildNdef, bindOsc, unbindOsc, updateUiLabels;

var meterHeight, tickWidth;

// ------------- constants for alignment -------------
meterHeight = 220;  // exact shared height for tick strip & meter
tickWidth   = 72;   // width for tick area (room for labels)

// ------------- UI bring-up -------------
Window.allWindows.do({ |w| if(w.name == "Meter Calibration Demo", { w.close }) });

window = Window("Meter Calibration Demo", Rect(160, 160, 540, 340))
    .background_(Color.white)
    .front;

paneColor = Color(0.10, 0.30, 0.10);

// ------------- Mapping (linear RMS -> UI) -------------
topDb   = 0.0;     // UI=1 at 0 dBFS RMS
floorDb = -120.0;  // UI=0 at -120 dBFS RMS
gamma   = 1.0;     // 1.0 = straight mapping in dB

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
ndefName       = \calSaw;
oscNameGui     = \calSaw_toGUI;
oscNameConsole = \calSaw_console;

ampDbChoices = [0, -6, -12, -18, -20, -60, -128];
currentAmpDb = -12;  // default on bring-up

ampToRmsDbSaw = { |peakDb|
    var peakLin, rmsLin, rmsDb;
    peakLin = peakDb.dbamp;        // peak amplitude as linear
    rmsLin  = peakLin / sqrt(3);   // RMS of a symmetric saw
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
        sig  = Saw.ar([freq, freq]) * amp;   // band-limited saw, stereo
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsDemo', 1);  // 20 Hz GUI updates
        sig
    });
    Ndef(ndefName).play(numChannels: 2);
};

valueFromMsg = { |msg|
    var v, sz;
    v = 0.0;
    if(msg.notNil) {
        sz = msg.size;
        if(sz >= 4) { v = msg[sz - 1].asFloat; };  // take final RMS element
    };
    v.clip(0.0, 1.0)
};

// ------------- GUI controls (top row) -------------
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
    ampMenu,                 // no .stretch_; we control spacing with explicit spacers
    UserView().minSize_(Size(12, 0)),  // spacer
    nil
);

// Meter + ticks (side-by-side, identical heights)
meter = LevelIndicator()
    .fixedWidth_(30)
    .fixedHeight_(meterHeight)    // keep height exactly in sync with tick strip
    .warning_(0.50)
    .critical_(0.80);

tickView = UserView()
    .minSize_(Size(tickWidth, meterHeight))
    .maxSize_(Size(tickWidth, meterHeight))
    .background_(Color.white);

// Whole layout
layout = VLayout(
    UserView().minSize_(Size(0, 8)),  // spacer
    controlsRow,
    UserView().minSize_(Size(0, 6)),
    HLayout(
        tickView,                         // left: tick strip (draws header inside)
        UserView().minSize_(Size(8, 0)),  // spacer between tick and meter
        meter,
        UserView().minSize_(Size(12, 0)),
        VLayout(
            labelRms,
            UserView().minSize_(Size(6, 6)),
            labelInfo
        ).margins_(2)
    ).margins_(8)
).margins_(8);

window.layout = layout;

// ------------- Tick drawing (inside the fixed-height tickView) -------------
tickView.drawFunc_({ |v|
    var ctx, w, h, leftPad, rightPad, tickLong, tickShort, db, step, y, u, text;
    var font, zeroColor, tickColor;

    ctx = Pen;
    w = v.bounds.width;
    h = v.bounds.height;

    leftPad  = 6;
    rightPad = w - 6;  // right margin; labels must fit before this
    tickLong  = 14;
    tickShort = 9;
    step = 6;         // every 6 dB

    zeroColor = Color.red;
    tickColor = Color.gray(0.22);
    font = Font("Helvetica", 10);

    ctx.use {
        // background
        ctx.color = Color.white;
        ctx.addRect(Rect(0, 0, w, h));
        ctx.fill;

        // small "dBFS" header at top-left (doesn't change layout height)
        ctx.stringAtPoint("dBFS", Point(leftPad, 2), Font("Helvetica", 10), Color.gray(0.25));

        // grid line at 0 dB
        u = mapDbToUi.(0, topDb, floorDb, gamma);
        y = (1 - u) * h;
        ctx.color = zeroColor.alpha_(0.35);
        ctx.width = 1.0;
        ctx.moveTo(Point(1, y));
        ctx.lineTo(Point(w - 1, y));
        ctx.stroke;

        // ticks every 6 dB down to floor
        db = 0;
        while({ db >= floorDb }, {
            var isMajor, tickLen, labelX;
            isMajor = ((db % 12) == 0) or: { db == 0 };
            tickLen = isMajor.if(tickLong, tickShort);

            u = mapDbToUi.(db, topDb, floorDb, gamma);
            y = (1 - u) * h;

            // tick
            ctx.color = (db == 0).if(zeroColor, tickColor);
            ctx.width = 1.0;
            ctx.moveTo(Point(leftPad, y));
            ctx.lineTo(Point(leftPad + tickLen, y));
            ctx.stroke;

            // label on majors (12 dB) and 0 dB
            if(isMajor) {
                labelX = leftPad + tickLong + 4;
                text = db.asString;
                if(labelX < (rightPad - 6)) {
                    ctx.stringAtPoint(text, Point(labelX, y - 6), font, Color.black);
                };
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
        lin  = valueFromMsg.(msg);
        ui   = mapLinToUi.(lin, topDb, floorDb, gamma);
        rmsDb = lin.max(1e-9).ampdb;

        {
            meter.value_(ui);
            labelRms.string_("RMS: " ++ rmsDb.round(0.1) ++ " dBFS  (UI: " ++ ui.round(0.003) ++ ")");
        }.defer;
    }, '/peakrmsDemo');

    // optional console OSCdef omitted to keep output quiet
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
            ++ pred.round(0.1) ++ " dBFS   |   top=" ++ topDb ++ " , floor=" ++ floorDb);
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
    {
        ampMenu.items = ampDbChoices.collect({ |x| x.asString ++ " dBFS (peak)" });
    }.defer;
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
// One-liners (optional): change amplitude without using the menu
// -------------------------------------------------------------------------
~cal_ampDb = { |db| var val; val = db.asFloat; Ndef(\calSaw).set(\amp, val.dbamp); ("set peak = " ++ val ++ " dBFS").postln; };

~cal_ampDb.(0);
~cal_ampDb.(-6);
~cal_ampDb.(-12);
~cal_ampDb.(-18);
~cal_ampDb.(-20);
~cal_ampDb.(-60);
~cal_ampDb.(-128);
