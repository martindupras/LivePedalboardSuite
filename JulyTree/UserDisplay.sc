// userFeedbackSystem.sc
// MD 20250806

// Used to display states of the system and such.

UserDisplay {

	var <>window;
	var <>modeText;
	var <>queueText;
	var <>lastCommandText;
	var <>userChoicesText;
	var <>statusText;

	*new{
		^super.new.init
	}

	init{
		"userFeedback created".postln;

		// create window
		window = Window("user display", Rect(10, 400, 800, 600));

		// create the fields:
		modeText = StaticText(window).string_("modeText");
		queueText = StaticText(window).string_("queueText");
		lastCommandText = StaticText(window).string_("lastCommandText");
		userChoicesText = StaticText(window).string_("userChoicesText");
		statusText = StaticText(window).string_(""); // choose appropriate position and size


		// add layouts to the window
		window.layout =
		VLayout(
			modeText,
			queueText,
			lastCommandText,
			userChoicesText,
			statusText
		);

		// bring window to front:
		window.front;
		^this // return instance of UserDisplay
	}

	updateTextField{
		|box, msg|
		switch (box,
			\state, { modeText.string_(msg)},
			\queue, { queueText.string_(msg)},
			\lastCommand, { lastCommandText.string_(msg)},
			\choices, { userChoicesText.string_(msg)}
		);

		postln("box:" + box);
		postln("msg:" + msg);
	}

	updateStatus { |text|
    ("🖥 Status update: " ++ text).postln;
    { this.statusText.string = text; }.defer; // assuming you have a GUI element called statusText
}


} //end of class