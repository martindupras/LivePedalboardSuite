// MagicDisplayGUI_GridDemo_Ext_SetOperations.sc
// v0.1.0
// MD 2025-09-22 22:36 BST

/* Purpose
   - Let CommandManager.updateDisplay push the current fret→choice list
     into MagicDisplayGUI_GridDemo's "Choices" panel.
   Style
   - AppClock-only UI; var-first; lowercase; no server.sync.
*/

+ MagicDisplayGUI_GridDemo {
    setOperations { |lines|
        var text;
        text = (lines ? []).join("\n");
        this.queueUi({
            if(choicesText.notNil) { choicesText.string = text };
        });
        ^this
    }
}
