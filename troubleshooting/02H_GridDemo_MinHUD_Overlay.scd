// 02H_GridDemo_MinHUD_Overlay.scd
// v0.1.3
// MD 2025-09-29 13:42 BST

/* Purpose
 - Add a compact overlay HUD (STATE line + CHOICES list) to the GridDemo window,
   without touching GridDemo’s privates. Uses StaticText for guaranteed visibility.
 - Export helpers: ~hud_setState.(string), ~hud_setChoices.([lines]),
   and ~hud_moveTopRight.(marginInt) to re-anchor after resize.
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; single MagicDisplayGUI window.
*/

(
var ensureGui, killOld, mkOverlay, positionTopRight, hookResize, frontHud;

ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

killOld = {
    var host;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.notNil) {
        host.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).do(_.remove);
    };
    ~hud_setState = nil;
    ~hud_setChoices = nil;
    ~hud_moveTopRight = nil;
};

mkOverlay = {
    var host, r, panel, title, stateLabel, choicesLabel, choicesBox;
    var pad, width, height, titleH, stateH, lineH;

    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02H: host view is nil; aborting.".warn; ^nil };

    r = host.bounds;
    width = 360;                       // room for multi-line CHOICES
    height = 190;                      // compact but readable
    pad = 8;
    titleH = 16;
    stateH = 18;
    lineH = 14;

    panel = CompositeView(host).name_("MDG_MINHUD");
    panel.background = Color(0,0,0,0.30);
    panel.bounds = Rect(r.width - (width + 12), 10, width, height);
    panel.border = 1;
    panel.borderColor = Color(1,1,1,0.25);
    panel.front;

    title = StaticText(panel)
        .string_("MIN-HUD")
        .font_(Font("Monaco", 12))
        .stringColor_(Color(1,1,1,0.85))
        .bounds_(Rect(pad, pad, width - 2*pad, titleH));

    stateLabel = StaticText(panel)
        .string_("(state)")
        .font_(Font("Monaco", 11))
        .stringColor_(Color(1,1,1,0.95))
        .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, stateH));

    choicesLabel = StaticText(panel)
        .string_("CHOICES:")
        .font_(Font("Monaco", 11))
        .stringColor_(Color(1,1,1,0.85))
        .bounds_(Rect(pad, pad + titleH + 4 + stateH + 6, width - 2*pad, lineH));

    choicesBox = StaticText(panel)
        .string_("(choices)")
        .align_(\topLeft)
        .font_(Font("Monaco", 10))
        .stringColor_(Color(0.95,0.95,0.95))
        .bounds_(Rect(
            pad,
            pad + titleH + 4 + stateH + 6 + lineH + 2,
            width - 2*pad,
            height - (titleH + 4 + stateH + 6 + lineH + 2 + pad)
        ));

    // ——— Helpers (exported) ———
    ~hud_setState = { arg textString;
        AppClock.sched(0.0, {
            stateLabel.string = textString.asString;
            nil
        });
    };

    ~hud_setChoices = { arg linesArray;
        var s;
        s = (linesArray ? []).collect(_.asString).join("\n");
        AppClock.sched(0.0, {
            choicesBox.string = s.size > 0 ? s : "—";
            nil
        });
    };

    positionTopRight = { arg margin = 10;
        var rb;
        rb = host.bounds;
        AppClock.sched(0.0, {
            panel.bounds = Rect(rb.width - (width + margin), margin, width, height);
            panel.front;
            nil
        });
    };
    ~hud_moveTopRight = positionTopRight;
    positionTopRight.value(10);
};

hookResize = {
    var win;
    win = ~gui.tryPerform(\window);
    if(win.notNil) {
        win.onResize = { (~hud_moveTopRight !? { ~hud_moveTopRight.(10) }) };
    };
};

frontHud = {
    if(~gui.respondsTo(\window)) { ~gui.window.front };
    (~hud_setState !? { ~hud_setState.("HUD ready (GridDemo overlay)") });
    (~hud_setChoices !? { ~hud_setChoices.(["(no choices yet)"]) });
};

AppClock.sched(0.00, { ensureGui.value; killOld.value; mkOverlay.value; hookResize.value; frontHud.value; nil });
)
