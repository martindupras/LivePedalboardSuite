// Compat_MagicDisplayGUI_QueueUi_Ext.sc
// v0.1.1
// MD 2025-09-23

+MagicDisplayGUI {
    queueUi { |taskOrText|
        var doIt;
        doIt = {
            if(taskOrText.isKindOf(Function)) {
                taskOrText.value;
            }{
                if(this.respondsTo(\showExpectation)) {
                    this.showExpectation(taskOrText.asString, 0);
                }{
                    taskOrText.asString.postln;
                };
            };
            nil
        };
        AppClock.sched(0.0, doIt);
        ^this
    }
}

+MagicDisplayGUI_GridDemo {
    queueUi { |taskOrText|
        var doIt;
        doIt = {
            if(taskOrText.isKindOf(Function)) {
                taskOrText.value;
            }{
                if(this.respondsTo(\showExpectation)) {
                    this.showExpectation(taskOrText.asString, 0);
                }{
                    taskOrText.asString.postln;
                };
            };
            nil
        };
        AppClock.sched(0.0, doIt);
        ^this
    }
}
