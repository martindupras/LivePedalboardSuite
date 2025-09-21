
// Define the UserDisplay class
TESTUserDisplay {
    var <stateBox, <queueBox, <lastCommandBox, <choicesBox;
    var window;

    *new {
        ^super.new.init;
    }

    init {
        window = Window("User Display", Rect(100, 100, 400, 300)).front;

        stateBox = StaticText(window, Rect(10, 10, 380, 20))
            .string_("State: empty");

        queueBox = StaticText(window, Rect(10, 40, 380, 20))
            .string_("Queue: []");

        lastCommandBox = StaticText(window, Rect(10, 70, 380, 20))
            .string_("Last Command: none");

        choicesBox = StaticText(window, Rect(10, 100, 380, 180))
            .string_("Choices:\n1: oscil\n2: pinknoise\n3: whitenoise");

        window.onClose_({ this.free });
    }

    display { |boxSymbol, message|
        switch(boxSymbol,
            \state, { stateBox.string_("State: " ++ message); },
            \queue, { queueBox.string_("Queue: " ++ message); },
            \lastCommand, { lastCommandBox.string_("Last Command: " ++ message); },
            \choices, { choicesBox.string_("Choices:\n" ++ message); },
            { "Unknown box symbol: %".format(boxSymbol).postln }
        );
    }

    free {
        window.close;
    }
}


