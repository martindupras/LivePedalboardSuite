// MagicDisplayGUI_GridDemo_Ext_TestMarker.sc
// v0.1.0
// MD 2025-09-24 23:59 BST

/*
Purpose
- Draw unambiguous landmarks INSIDE the right CURRENT/NEXT panel (middle-right column):
  • Fuchsia border built from 4 thin CompositeViews (no drawFunc)
  • Yellow highlight inside the 'eff' row (anchor)
  • Marker bar near 'eff': ORANGE below (clamped) or SKY-BLUE above (clamped)
- Absolutely no layout mutations; no drawing math inside drawFuncs; only known-good SC GUI.

Style
- Class extension; var-first in all methods; descriptive variable names.
- Views are created as named children of rightPanel so we can remove them safely.
*/

+ MagicDisplayGUI_GridDemo {

  // ---------- helpers: find/remove named child on rightPanel ----------
  tm_findChildByName { arg childNameString;
    var foundView, childCount, childIndex, childView, childNameMaybe;
    foundView = nil;
    if(rightPanel.notNil) {
      childCount = rightPanel.children.size;
      childIndex = 0;
      childCount.do({
        childView = rightPanel.children[childIndex];
        childNameMaybe = if(childView.respondsTo(\name), { childView.name }, { nil });
        if(childNameMaybe == childNameString) { foundView = childView };
        childIndex = childIndex + 1;
      });
    };
    ^foundView
  }

  tm_removeChildByName { arg childNameString;
    var viewToRemove;
    viewToRemove = this.tm_findChildByName(childNameString);
    if(viewToRemove.notNil) { viewToRemove.remove };
    ^this
  }

  // ---------- clear all test markers/borders ----------
  testMarker_clear {
    this.tm_removeChildByName("MDG_TM_BORDER_TOP");
    this.tm_removeChildByName("MDG_TM_BORDER_BOTTOM");
    this.tm_removeChildByName("MDG_TM_BORDER_LEFT");
    this.tm_removeChildByName("MDG_TM_BORDER_RIGHT");
    this.tm_removeChildByName("MDG_TM_EFF_HI");
    this.tm_removeChildByName("MDG_TM_MARKER");
    ^this
  }

  // ---------- show a bold fuchsia border (4 thin views) ----------
  testMarker_showPanelBorder {
    var ensureFunc;

    if(rightPanel.isNil) { "testMarker_showPanelBorder: rightPanel is nil".warn; ^this };

    ensureFunc = {
      var panelBounds, thickness, topView, bottomView, leftView, rightView, colorFuchsia;

      // clean previous
      this.testMarker_clear;

      panelBounds   = rightPanel.bounds;
      thickness     = 3;
      colorFuchsia  = Color(1.0, 0.0, 1.0, 0.85);

      topView = CompositeView(rightPanel).name_("MDG_TM_BORDER_TOP");
      topView.background = colorFuchsia;
      topView.bounds = Rect(0, 0, panelBounds.width, thickness);

      bottomView = CompositeView(rightPanel).name_("MDG_TM_BORDER_BOTTOM");
      bottomView.background = colorFuchsia;
      bottomView.bounds = Rect(0, panelBounds.height - thickness, panelBounds.width, thickness);

      leftView = CompositeView(rightPanel).name_("MDG_TM_BORDER_LEFT");
      leftView.background = colorFuchsia;
      leftView.bounds = Rect(0, 0, thickness, panelBounds.height);

      rightView = CompositeView(rightPanel).name_("MDG_TM_BORDER_RIGHT");
      rightView.background = colorFuchsia;
      rightView.bounds = Rect(panelBounds.width - thickness, 0, thickness, panelBounds.height);

      // bring to front in a stable order
      topView.front; bottomView.front; leftView.front; rightView.front;
    };

    AppClock.sched(0.0, { ensureFunc.value; nil });
    ^this
  }

  // ---------- highlight the 'eff' row (yellow translucent) ----------
  testMarker_highlightEff {
    var ensureFunc;

    if(rightPanel.isNil or: { rightEff.isNil }) {
      "testMarker_highlightEff: rightPanel or rightEff is nil".warn; ^this
    };

    ensureFunc = {
      var effBounds, highlightView, colorYellow;

      // remove old eff highlight only
      this.tm_removeChildByName("MDG_TM_EFF_HI");

      effBounds = rightEff.bounds;
      colorYellow = Color(1.0, 1.0, 0.0, 0.45);

      highlightView = CompositeView(rightPanel).name_("MDG_TM_EFF_HI");
      highlightView.background = colorYellow;
      highlightView.bounds = Rect(
        effBounds.left + 2,
        effBounds.top + 2,
        (effBounds.width - 4).max(4),
        (effBounds.height - 4).max(4)
      );
      highlightView.front;
    };

    AppClock.sched(0.0, { ensureFunc.value; nil });
    ^this
  }

  // ---------- place a marker bar NEAR the 'eff' row (positionSymbol: \below or \above) ----------
  testMarker_showNearEff { arg positionSymbol = \below, barHeight = 24;
    var ensureFunc;

    if(rightPanel.isNil or: { rightEff.isNil }) {
      "testMarker_showNearEff: rightPanel or rightEff is nil".warn; ^this
    };

    ensureFunc = {
      var panelBounds, effBounds, leftInset, rightInset, gapPixels;
      var desiredTop, finalTop, finalHeight, markerRect, markerView;
      var colorOrange, colorSkyBlue, markerColor;

      // remove any previous marker (keep border/eff highlight)
      this.tm_removeChildByName("MDG_TM_MARKER");

      panelBounds = rightPanel.bounds;
      effBounds   = rightEff.bounds;

      leftInset   = 6;
      rightInset  = 6;
      gapPixels   = 4;
      colorOrange = Color(1.0, 0.50, 0.0, 0.90);
      colorSkyBlue= Color(0.10, 0.65, 1.0, 0.90);

      if(positionSymbol == \below) {
        markerColor = colorOrange;
        desiredTop  = effBounds.bottom + gapPixels;
        finalHeight = barHeight.max(8);
        if(desiredTop + finalHeight > panelBounds.height) {
          finalHeight = (panelBounds.height - desiredTop).max(8);
        };
        finalTop = desiredTop.min(panelBounds.height - finalHeight).max(0);
      } {
        markerColor = colorSkyBlue;  // \above
        finalHeight = barHeight.max(8);
        desiredTop  = effBounds.top - gapPixels - finalHeight;
        if(desiredTop < 0) {
          finalHeight = (effBounds.top - gapPixels).max(8);
          desiredTop  = 0;
        };
        finalTop = desiredTop;
      };

      markerRect = Rect(
        leftInset,
        finalTop,
        (panelBounds.width - (leftInset + rightInset)).max(8),
        finalHeight
      );

      markerView = CompositeView(rightPanel).name_("MDG_TM_MARKER");
      markerView.background = markerColor;
      markerView.bounds = markerRect;
      markerView.front;

      "—— TestMarker ——".postln;
      ("rightPanel.bounds: " ++ panelBounds).postln;
      ("rightEff.bounds:   " ++ effBounds).postln;
      ("marker.bounds:     " ++ markerRect).postln;
    };

    AppClock.sched(0.0, { ensureFunc.value; nil });
    ^this
  }
}
