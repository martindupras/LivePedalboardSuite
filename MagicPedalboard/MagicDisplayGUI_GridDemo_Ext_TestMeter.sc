// MagicDisplayGUI_GridDemo_Ext_TestMeter.sc
// v0.1.0
// MD 2025-09-24 23:59 BST

/*
Purpose
- Draw a small horizontal "debug meter" inside the right CURRENT/NEXT panel (middle-right column),
  positioned relative to the 'eff:' row (just BELOW by default; clamped to stay inside the panel).
- Step 1: run with a smoothed RANDOM driver to prove GUI refresh + horizontal motion.
- Step 2: attach to live audio via SendReply.kr paths '/ampA' or '/ampB'.

Style
- Class extension; known-good SuperCollider only.
- Var-first in all blocks; descriptive variable names (>=3 chars).
- Minimal state stored in Library under category \MD_TM and key this.identityHash.
*/

+ MagicDisplayGUI_GridDemo {

  // ---------- tiny state bag in Library (per GUI instance) ----------
  tm2_state {
    var categorySymbol, keyInt, dict;
    categorySymbol = \MD_TM;
    keyInt = this.identityHash;
    dict = Library.at(categorySymbol, keyInt);
    if(dict.isNil) {
      dict = IdentityDictionary.new;
      Library.put(categorySymbol, keyInt, dict);
    };
    ^dict
  }

  tm2_put { arg keySymbol, valueObject;
    var stateDict;
    stateDict = this.tm2_state;
    stateDict.put(keySymbol, valueObject);
    ^this
  }

  tm2_get { arg keySymbol, defaultValue = nil;
    var stateDict;
    stateDict = this.tm2_state;
    ^(stateDict.includesKey(keySymbol).if({ stateDict.at(keySymbol) }, { defaultValue }))
  }

  // ---------- compute the meter rectangle relative to 'eff' (below or above) ----------
  tm2_computeMeterRect { arg positionSymbol = \below, barHeight = 24;
    var panelBounds, effBounds;
    var leftInset, rightInset, gapPixels;
    var desiredTop, finalTop, finalHeight, rectResult;

    if(rightPanel.isNil or: { rightEff.isNil }) { ^Rect(0,0,0,0) };

    panelBounds = rightPanel.bounds;
    effBounds   = rightEff.bounds;

    leftInset   = 6;
    rightInset  = 6;
    gapPixels   = 4;

    if(positionSymbol == \below) {
      desiredTop  = effBounds.bottom + gapPixels;
      finalHeight = barHeight.max(8);
      if(desiredTop + finalHeight > panelBounds.height) {
        finalHeight = (panelBounds.height - desiredTop).max(8);
      };
      finalTop = desiredTop.min(panelBounds.height - finalHeight).max(0);
    } {
      // \above
      finalHeight = barHeight.max(8);
      desiredTop  = effBounds.top - gapPixels - finalHeight;
      if(desiredTop < 0) {
        finalHeight = (effBounds.top - gapPixels).max(8);
        desiredTop  = 0;
      };
      finalTop = desiredTop;
    };

    rectResult = Rect(
      leftInset,
      finalTop,
      (panelBounds.width - (leftInset + rightInset)).max(8),
      finalHeight
    );
    ^rectResult
  }

  // ---------- create the meter UserView at the computed rectangle ----------
  testMeter_showAtEff { arg positionSymbol = \below, barHeight = 24;
    var ensureFunc;

    if(rightPanel.isNil or: { rightEff.isNil }) {
      "testMeter_showAtEff: rightPanel or rightEff is nil".warn; ^this
    };

    ensureFunc = {
      var meterRect, meterUserView;

      // remove any previous meter view
      this.testMeter_remove;

      meterRect = this.tm2_computeMeterRect(positionSymbol, barHeight);

      meterUserView = UserView(rightPanel).name_("MDG_TM2_METER");
      meterUserView.background = Color.clear;
      meterUserView.bounds = meterRect;

      // drawFunc: trough + horizontal fill
      meterUserView.drawFunc = { arg viewLocal;
        var viewBounds, padPixels, troughRect, valueNow, fillWidth, fillRect;

        viewBounds = viewLocal.bounds;
        padPixels  = 2;

        troughRect = Rect(
          padPixels, padPixels,
          viewBounds.width  - (padPixels * 2),
          viewBounds.height - (padPixels * 2)
        );

        // trough
        Pen.color = Color(0.80, 0.82, 0.86, 0.60);
        Pen.addRect(troughRect); Pen.fill;

        // horizontal fill
        valueNow  = (this.tm2_get(\meterVal, 0.0)).clip(0, 1);
        fillWidth = (troughRect.width * valueNow).max(0);
        fillRect  = Rect(troughRect.left, troughRect.top, fillWidth, troughRect.height);

        Pen.color = Color(0.15, 0.65, 0.25, 0.95);  // green-ish
        Pen.addRect(fillRect); Pen.fill;

        // border
        Pen.color = Color.gray(0.20);
        Pen.strokeRect(Rect(0.5, 0.5, viewBounds.width - 1, viewBounds.height - 1));
      };

      meterUserView.front;

      this.tm2_put(\meterView, meterUserView);
      this.tm2_put(\meterVal, 0.0);
    };

    AppClock.sched(0.0, { ensureFunc.value; nil });
    ^this
  }

  // ---------- random driver (prove GUI refresh + orientation) ----------
  testMeter_startRandom {
    var startFunc;

    startFunc = {
      var existingTask, meterUserView, meterTaskRoutine;

      // stop any prior driver
      this.testMeter_stop;

      meterUserView = this.tm2_get(\meterView);
      if(meterUserView.isNil) { "testMeter_startRandom: meter not shown—call testMeter_showAtEff first.".warn; ^this };

      meterTaskRoutine = Routine({
        var currentVal, targetVal, stepSeconds;
        currentVal = this.tm2_get(\meterVal, 0.0);
        stepSeconds = 0.06;  // ~16 Hz
        inf.do {
          targetVal  = 1.0.rand;
          currentVal = (currentVal * 0.75) + (targetVal * 0.25);
          this.tm2_put(\meterVal, currentVal);
          AppClock.sched(0.0, { var uv = this.tm2_get(\meterView); if(uv.notNil){ uv.refresh }; nil });
          stepSeconds.wait;
        }
      });

      this.tm2_put(\meterTask, meterTaskRoutine);
      meterTaskRoutine.play(AppClock);
    };

    AppClock.sched(0.0, { startFunc.value; nil });
    ^this
  }

  // ---------- attach to live audio via '/ampA' or '/ampB' ----------
  testMeter_attach { arg whichChain = \A;
    var attachFunc;

    attachFunc = {
      var meterUserView, oscKeyA, oscKeyB, oscDefAmpA, oscDefAmpB;

      this.testMeter_stop;  // stop prior drivers

      meterUserView = this.tm2_get(\meterView);
      if(meterUserView.isNil) { "testMeter_attach: meter not shown—call testMeter_showAtEff first.".warn; ^this };

      // unique OSCdef keys per GUI instance
      oscKeyA = ("mdTmAmpA_" ++ this.identityHash).asSymbol;
      oscKeyB = ("mdTmAmpB_" ++ this.identityHash).asSymbol;

      oscDefAmpA = OSCdef(oscKeyA, { arg msg;
        var leftVal, rightVal, peakVal, smoothVal;
        leftVal  = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        rightVal = (msg.size > 4).if({ msg[4] }, { leftVal }).asFloat;
        peakVal  = max(leftVal, rightVal).clip(0, 1);
        smoothVal = (this.tm2_get(\meterVal, 0.0) * 0.7) + (peakVal * 0.3);
        this.tm2_put(\meterVal, smoothVal);
        AppClock.sched(0.0, { var uv = this.tm2_get(\meterView); if(uv.notNil){ uv.refresh }; nil });
      }, '/ampA');

      oscDefAmpB = OSCdef(oscKeyB, { arg msg;
        var leftVal, rightVal, meanVal, smoothVal;
        leftVal  = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        rightVal = (msg.size > 4).if({ msg[4] }, { leftVal }).asFloat;
        meanVal  = ((leftVal + rightVal) * 0.5).clip(0, 1);
        smoothVal = (this.tm2_get(\meterVal, 0.0) * 0.7) + (meanVal * 0.3);
        this.tm2_put(\meterVal, smoothVal);
        AppClock.sched(0.0, { var uv = this.tm2_get(\meterView); if(uv.notNil){ uv.refresh }; nil });
      }, '/ampB');

      this.tm2_put(\oscA, oscDefAmpA);
      this.tm2_put(\oscB, oscDefAmpB);

      // enable only one path
      if(whichChain == \A) { oscDefAmpB.disable } { oscDefAmpA.disable };
    };

    AppClock.sched(0.0, { attachFunc.value; nil });
    ^this
  }

  // ---------- stop drivers (random and OSC) ----------
  testMeter_stop {
    var stopFunc;

    stopFunc = {
      var existingTask, oscDefA, oscDefB;

      existingTask = this.tm2_get(\meterTask);
      if(existingTask.notNil) { existingTask.stop; this.tm2_put(\meterTask, nil) };

      oscDefA = this.tm2_get(\oscA);
      if(oscDefA.notNil) { oscDefA.free; this.tm2_put(\oscA, nil) };

      oscDefB = this.tm2_get(\oscB);
      if(oscDefB.notNil) { oscDefB.free; this.tm2_put(\oscB, nil) };
    };

    AppClock.sched(0.0, { stopFunc.value; nil });
    ^this
  }

  // ---------- remove the meter view ----------
  testMeter_remove {
    var removeFunc;

    removeFunc = {
      var meterUserView;
      // stop activity first
      this.testMeter_stop;

      meterUserView = this.tm2_get(\meterView);
      if(meterUserView.notNil) { meterUserView.remove; this.tm2_put(\meterView, nil) };
    };

    AppClock.sched(0.0, { removeFunc.value; nil });
    ^this
  }
}
