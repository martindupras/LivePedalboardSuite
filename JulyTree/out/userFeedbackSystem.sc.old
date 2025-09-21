// userFeedbackSystem.sc
// MD 20250806

// Used to display states of the system and such.

UserDisplay {

	var <>window;
	var <>stateText;
	var <>queueText;
	var <>lastCommandText;
	var <>userChoicesText;

	//var window, stateText, queueText , lastCommandText, userChoicesText;

	*new{
		^super.new.init
	}

	init{
		"userFeedback created".postln;

		// create window
		window = Window("user display", Rect(10, 400, 800, 600));

		// create the fields:
		stateText = StaticText(window).string_("stateText");
		queueText = StaticText(window).string_("queueText");
		lastCommandText = StaticText(window).string_("lastCommandText");
		userChoicesText = StaticText(window).string_("userChoicesText");

		// add layouts to the window
		window.layout =
		HLayout(
			stateText,
			queueText,
			lastCommandText,
			userChoicesText
		);

		// bring window to front:
		window.front;
		^this // return instance of UserDisplay
	}

	display{
		|box, msg|
		switch (box,
			\state, { stateText.string_(msg)},
			\queue, { queueText.string_(msg)},
			\lastCommand, { lastCommandText.string_(msg)},
			\choices, { userChoicesText.string_(msg)}
		);

		postln("box:" + box);
		postln("msg:" + msg);
	}

} //end of class