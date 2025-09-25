// MagicDisplayGUI_FixChoicesColors_Ext.sc
// v0.1.2  — MD 2025-09-24 23:10 BST
/*
Purpose
- Make the "Choices" text high-contrast no matter how it is updated:
  updateTextField(\choices, ...) or setOperations([...]).
Style
- Class extension only; NO new ivars; var-first in every method; AppClock UI; no server.sync.
*/

+ MagicDisplayGUI_GridDemo {

    ensureChoicesPanel {
        var host, build;
        host = this.window.tryPerform(\view);
        if(host.isNil) { ^this };

        build = {
            var x, y, w, h;
            x = host.bounds.width - 360; y = 8; w = 352; h = 200;

            this.choicesPanel = this.choicesPanel ?? { CompositeView(host) };
            this.choicesPanel
                .background_(Color(0.15, 0.15, 0.15))
                .resize_(5)
                .bounds_(Rect(x, y, w, h));

            this.choicesTitle = this.choicesTitle ?? { StaticText(this.choicesPanel) };
            this.choicesTitle
                .string_("Choices")
                .stringColor_(Color(0.85, 0.85, 0.85))
                .align_(\left)
                .bounds_(Rect(8, 6, w - 16, 20));

            this.choicesText = this.choicesText ?? { TextView(this.choicesPanel) };
            this.choicesText
                .background_(Color(0.15, 0.15, 0.15))
                .stringColor_(Color.white)
                .font_(Font("Monaco", 12))
                .autoscroll_(true)
                .editable_(false)
                .bounds_(Rect(8, 28, w - 16, h - 36));
        };

        AppClock.sched(0.0, { build.value; nil });
        ^this
    }

    md_applyChoicesText { arg textString;
        var txt;
        txt = textString.asString;
        AppClock.sched(0.0, {
            this.ensureChoicesPanel;
            if(this.choicesText.notNil) {
                this.choicesText.stringColor_(Color.white);  // force high contrast
                this.choicesText.string_(txt);
            };
            nil
        });
        ^this
    }

    updateTextField { arg key, textString;
        var txt;
        txt = textString.asString;
        AppClock.sched(0.0, {
            switch(key,
                \choices, { this.md_applyChoicesText(txt) },
                \state,   { if(this.expectationView.notNil) { this.expectationView.string = txt } },
                \queue,   { if(this.expectationView.notNil) { this.expectationView.string = "Queue:\n" ++ txt } },
                \lastCommand, { if(this.expectationView.notNil) { this.expectationView.string = "Last: " ++ txt } },
                { /* no-op */ }
            );
            nil
        });
        ^this
    }

    setOperations { arg itemsArray;
        var s;
        s = (itemsArray ? []).collect(_.asString).join("\n");
        this.md_applyChoicesText(s);
        ^this
    }

    // optional manual nudge
    forceHighContrastChoices {
        this.md_applyChoicesText(this.choicesText.tryPerform(\string) ? "");
        ^this
    }
}
