// MagicDisplayGUI_GridDemo_Ext_Meters.scd
// v0.3.0
// MD 2025-09-24 23:56 BST

/*
Purpose
- Provide enableMeters(true): listen to /ampA and /ampB (from SendReply.kr)
  and draw two moving bars in meterStrip.
Style
- Class extension only; var-first; AppClock for UI; no server.sync.
*/

+ MagicDisplayGUI_GridDemo {

  enableMeters { arg on = true;
    var state, setupUI, install, remove;

    // Simple per-window state (no ivars added)
    state = (
      valA: 0.0,   // 0..1 (A bar)
      valB: 0.0,   // 0..1 (B bar)
      rxA:  nil,   // OSCdef handles
      rxB:  nil
    );

    setupUI = {
      if(meterStrip.notNil) {
        meterStrip.drawFunc = { |view|
          var b = view.bounds, pad = 8, w = b.width - (pad*2), h = b.height;
          var barH = ((h - (pad*2) - 4)/2).clip(8,14);
          var top1 = pad, top2 = pad + barH + 4;
          var a = state[\valA].clip(0,1), bb = state[\valB].clip(0,1);

          // backgrounds
          Pen.color = Color(0.2,0.2,0.2,0.15); Pen.addRect(Rect(pad, top1, w, barH)); Pen.fill;
          Pen.color = Color(0.2,0.2,0.2,0.15); Pen.addRect(Rect(pad, top2, w, barH)); Pen.fill;

          // dynamic fills
          Pen.color = Color(0.20, 0.70, 0.20); Pen.addRect(Rect(pad, top1, w * a,  barH)); Pen.fill;  // A
          Pen.color = Color(0.20, 0.40, 0.90); Pen.addRect(Rect(pad, top2, w * bb, barH)); Pen.fill;  // B

          // border
          Pen.color = Color.gray(0.5); Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
        };
      };
    };

    install = {
      setupUI.value;

      // IMPORTANT: these paths must match the ones used in SendReply.kr
      state[\rxA] = OSCdef(\mdAmpA, { |msg|
        // SendReply places floats after some metadata; first value is msg[3]
        var l = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        var r = (msg.size > 4).if({ msg[4] }, { l }).asFloat;
        // quick smoothing
        state[\valA] = (state[\valA] * 0.7) + (max(l, r) * 0.3);
        AppClock.sched(0.0, { if(meterStrip.notNil){ meterStrip.refresh }; nil });
      }, '/ampA');

      state[\rxB] = OSCdef(\mdAmpB, { |msg|
        var l = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        var r = (msg.size > 4).if({ msg[4] }, { l }).asFloat;
        var mean = ((l + r) * 0.5).clip(0,1);
        state[\valB] = (state[\valB] * 0.7) + (mean * 0.3);
        AppClock.sched(0.0, { if(meterStrip.notNil){ meterStrip.refresh }; nil });
      }, '/ampB');
    };

    remove = {
      if(state[\rxA].notNil) { state[\rxA].free; state[\rxA] = nil };
      if(state[\rxB].notNil) { state[\rxB].free; state[\rxB] = nil };
      if(meterStrip.notNil) {
        meterStrip.drawFunc = { |view|
          var b = view.bounds;
          Pen.color = Color.gray(0.7);
          Pen.strokeRect(Rect(0.5,0.5,b.width-1,b.height-1));
        };
        meterStrip.refresh;
      };
    };

    AppClock.sched(0.0, { if(on) { install.value } { remove.value }; nil });
    ^this
  }
}
