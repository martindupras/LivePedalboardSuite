// MagicDisplayGUI_GridDemo_Ext_ContrastFix.scd
// v0.1.0
// MD 2025-09-24 23:55 BST

/*
Purpose
- Ensure the Choices panel uses light text on a dark background.
Style
- Class extension only; var-first; AppClock UI; no server.sync.
*/

+ MagicDisplayGUI_GridDemo {

  fixChoicesContrast { arg fg = Color(0.96,0.96,0.96), bg = Color(0.12,0.12,0.12,0.92);
    var apply;
    apply = {
      if(choicesPanel.notNil) { choicesPanel.background = bg };
      if(choicesTitle.notNil) { choicesTitle.stringColor = fg };
      if(choicesText.notNil)  { choicesText.stringColor  = fg };
    };
    AppClock.sched(0.0, { apply.value; nil });
    ^this
  }

  // Keep existing behavior but guarantee readable \choices text
  updateTextField { arg box, msg;
    var doIt;
    doIt = {
      if(box == \choices) {
        if(choicesText.notNil) {
          choicesText.string = msg.asString;
          choicesText.stringColor = Color(0.96,0.96,0.96);  // light text
          if(choicesTitle.notNil) { choicesTitle.stringColor = Color(0.96,0.96,0.96) };
        };
      }{
        if(expectationView.notNil) {
          expectationView.string = "[" ++ box.asString ++ "] " ++ msg.asString;
        };
      };
    };
    AppClock.sched(0.0, { doIt.value; nil });
    ^this
  }
}
