/*-------------------------------------------------------------
SawMeter_SingleNdef_100Hz
v0.1.7
MD 2025-10-01 12:58

Purpose:
- One Ndef plays a 100 Hz sawtooth at selectable amplitudes (dBFS).
- Meter shows RMS directly; Peak overlaid via LevelIndicator.drawsPeak/peakLevel.
- Tick marks every 6 dB to the RIGHT; 0 dBFS line + 0..-6 dB headroom band.
- Floor extended to -72 dB so RMS at -60 dBFS is visible (saw RMS ≈ -4.77 dB below peak).
- Compact UI; no legend; returns -> a Window.

Style:
- var-first declarations; lowercase methods; no server.sync
- AppClock-only GUI refresh
- Single window whose name begins with "MagicDisplayGUI"
-------------------------------------------------------------*/

(
// ------------------ config + helpers ------------------
var window_name, floor_db, headroom_top_db, refresh_hz;
var ndef_name, reply_id, amp_db_list, default_db;
var close_existing_magic_windows;
var clamp_db, db_to_ui_frac, y_for_db_padded;

window_name      = "MagicDisplayGUI — Single Saw Meter (100 Hz)"; // must start with MagicDisplayGUI
floor_db         = -72;   // EXTENDED floor so RMS at -60 dBFS (~ -64.77) is visible
headroom_top_db  = -6;    // headroom shading top (visual only)
refresh_hz       = 30;    // GUI / telemetry refresh (Hz)

ndef_name        = \md_saw_100hz;
reply_id         = 9001;
amp_db_list      = [0, -6, -12, -18, -20, -60, -128];
default_db       = -18;

close_existing_magic_windows = {
    var to_close;
    to_close = Window.allWindows.select({ |w| w.name.asString.beginsWith("MagicDisplayGUI") });
    to_close.do({ |w| w.close });
};

// dB clamp + mapping (0 dBFS -> 1.0 UI; floor_db -> 0.0 UI)
clamp_db = { |db| db.clip(floor_db, 0) };
db_to_ui_frac = { |db|
    var dbc = clamp_db.(db);
    (dbc - floor_db) / (0 - floor_db); // 0 at floor, 1 at 0 dBFS
};

// y for dB with small padding so bottom tick is always visible
y_for_db_padded = { |db, h, pad = 1|
    var p = db_to_ui_frac.(db).clip(0, 1);     // 0..1 (floor..0dB)
    var y = pad + (h - 1 - 2*pad) * (1 - p);   // 0 at top
    y.clip(0, h - 1);
};

// ------------------ main ------------------
close_existing_magic_windows.value;

s.waitForBoot({
    var window, amp_menu_view, info_view, readout_view;
    var indicator, ticks_view;
    var oscdef_levels, updater;

    var last_rms_lin, last_peak_lin, current_amp_db, current_amp_lin;
    var set_amp_db, db_ticks;

    // clean server tree
    s.initTree;
    s.defaultGroup.freeAll;

    // ---------- Ndef with telemetry (literal defaults; set real values after) ----------
    Ndef(ndef_name, { |amp = 0.125, trigID = 1, uiHz = 30|
        var sig_st, mono, peak_est, rms_est;
        var win_samps, sumsq, mean, rms_audio, trig;

        sig_st  = Saw.ar(100) * amp ! 2;
        mono    = (sig_st[0] + sig_st[1]) * 0.5;

        peak_est = Amplitude.kr(mono, 0.0, 0.05); // peak-ish envelope
        win_samps = (SampleRate.ir * 0.05).max(1).asInteger; // ~50 ms RMS
        sumsq     = RunningSum.ar(mono.squared, win_samps);
        mean      = sumsq / win_samps;
        rms_audio = mean.sqrt;
        rms_est   = A2K.kr(rms_audio);

        trig = Impulse.kr(uiHz);
        SendReply.kr(trig, "/md/levels", [ peak_est, rms_est ], trigID);

        sig_st
    });

    Ndef(ndef_name).set(\amp, default_db.dbamp, \trigID, reply_id, \uiHz, refresh_hz);

    // ---------- UI + state ----------
    last_peak_lin   = 0.0;
    last_rms_lin    = 0.0;
    current_amp_db  = default_db;
    current_amp_lin = current_amp_db.dbamp;

    set_amp_db = { |db|
        current_amp_db  = db;
        current_amp_lin = db.dbamp;
        Ndef(ndef_name).set(\amp, current_amp_lin);
        info_view.string = "Amp: % dBFS (lin %)"
            .format(db.asInteger, current_amp_lin.round(1e-6));
    };

    // ticks every 6 dB from 0 down to floor_db (== -72)
    db_ticks = Array.series(((0 - floor_db) / 6).asInteger + 1, 0, -6)
        .select({ |db| db >= floor_db });

    // ---------- window & views (compact) ----------
    window = Window(window_name, Rect(100, 100, 360, 230)).alwaysOnTop_(true);

    amp_menu_view = PopUpMenu(window, Rect(16, 16, 150, 22))
        .items_(amp_db_list.collect({ |db| "% dBFS".format(db) }))
        .action_({ |m| set_amp_db.(amp_db_list[m.value]) });

    info_view = StaticText(window, Rect(176, 16, 168, 22))
        .align_(\left)
        .stringColor_(Color.gray(0.1));

    // RMS bar with Peak overlay (normalized UI fractions 0..1)
    indicator = LevelIndicator(window, Rect(16, 56, 36, 160))
        .style_(\continuous)
        .warning_(0.85)
        .critical_(0.95)
        .drawsPeak_(true);

    // ticks to the RIGHT of the meter (compact)
    ticks_view = UserView(window, Rect(58, 56, 110, 160))
        .background_(Color(0.94, 0.94, 0.96));

    // numeric readout (RMS & Peak in dBFS)
    readout_view = StaticText(window, Rect(176, 56, 168, 20))
        .align_(\left)
        .stringColor_(Color.gray(0.1));

    // ticks drawing (0..-6 headroom band; -72 floor; -60 visible)
    ticks_view.drawFunc_({
        var b, w, h, y0, y_head, font;
        b = ticks_view.bounds; w = b.width; h = b.height;
        font = Font(Font.default.name, 11);

        // background
        Pen.color = Color(0.96, 0.96, 0.98);
        Pen.fillRect(Rect(0, 0, w, h));

        // headroom band (0..-6)
        y0    = y_for_db_padded.(0, h, 1);
        y_head = y_for_db_padded.(headroom_top_db, h, 1);
        Pen.color = Color(1.0, 0.8, 0.8, 0.35);
        Pen.fillRect(Rect(0, y0, w, (y_head - y0)));

        // 0 dBFS line (red)
        Pen.color = Color(0.8, 0.1, 0.1, 0.9);
        Pen.width = 1.0;
        Pen.moveTo(Point(0, y0));
        Pen.lineTo(Point(w, y0));
        Pen.stroke;

        // -6 dB line
        Pen.color = Color(0.6, 0.2, 0.2, 0.9);
        Pen.width = 1.0;
        Pen.moveTo(Point(0, y_head));
        Pen.lineTo(Point(w, y_head));
        Pen.stroke;

        // ticks + labels (0, -6, -12, ... down to -72)
        db_ticks.do({ |db|
            var y, major, tick_len, label, lx, ly;
            y = y_for_db_padded.(db, h, 1);
            major = (((db.asInteger % 12) == 0) or: (db == 0));
            tick_len = major.if(12, 8);
            label = "% dB".format(db.asInteger);

            Pen.color = Color(0.25, 0.25, 0.28, 1.0);
            Pen.width = 1.0;
            Pen.moveTo(Point(0, y));
            Pen.lineTo(Point(tick_len, y));
            Pen.stroke;

            Pen.color = Color(0.15, 0.15, 0.16, 1.0);
            lx = tick_len + 4;
            ly = (y - 7).clip(0, h - 14);
            Pen.stringAtPoint(label, Point(lx, ly), font);
        });
    });

    // ---------- OSC + updater ----------
    oscdef_levels = OSCdef(\md_levels, { |msg|
        // msg = [ '/md/levels', nodeID, replyID, peak, rms ]
        if (msg[2] == reply_id) {
            last_peak_lin = msg[3].asFloat.max(0);
            last_rms_lin  = msg[4].asFloat.max(0);
        };
    }, '/md/levels', s.addr);

    updater = Routine({
        var spf = 1.0 / refresh_hz;
        var min_ui = 1.0 / 160.0; // ensure 1 px visible if clamped to floor
        inf.do({
            {
                var db_rms, db_peak, p_rms, p_peak;

                db_rms  = last_rms_lin.max(1e-12).ampdb;  // dBFS
                db_peak = last_peak_lin.max(1e-12).ampdb; // dBFS

                // Normalize to UI 0..1 (0=floor, 1=0dB)
                p_rms  = db_to_ui_frac.(db_rms).clip(0, 1);
                p_peak = db_to_ui_frac.(db_peak).clip(0, 1);

                // show a 1px sliver if p_rms == 0 (below floor)
                p_rms = (p_rms <= 0).if(min_ui, p_rms);

                indicator.value_(p_rms);
                indicator.peakLevel_(p_peak);

                readout_view.string = "RMS: % dBFS | Peak: % dBFS"
                    .format(clamp_db.(db_rms).round(0.1), clamp_db.(db_peak).round(0.1));

                indicator.refresh;
                ticks_view.refresh;
            }.defer;
            spf.wait;
        });
    }).play(AppClock);

    // ---------- bring up ----------
    Ndef(ndef_name).play;
    set_amp_db.(default_db);
    amp_menu_view.value = amp_db_list.indexOf(default_db).max(0);

    window.onClose_({
        updater.stop;
        oscdef_levels.free;
        Ndef(ndef_name).stop(0.1);
        // Ndef(ndef_name).clear; // uncomment to remove definition
    });

    window.front;

    // return -> a Window
    window;
});
)