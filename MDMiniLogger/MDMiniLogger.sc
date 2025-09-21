// MDMiniLogger.sc
// v0.3.3
// MD 20250919-13:51

// access with MDMiniLogger.get (which creates the instance if there isn't one)
// verbosity levels: 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG, 4=TRACE

MDMiniLogger : Object {
	classvar < logger;
	classvar verbosityNames;
	var < verbosity;
	var < enabled;

	// 3.1 fix
	*initClass {
		verbosityNames = ["ERROR", "WARN", "INFO", "DEBUG", "TRACE"];
		logger = nil; // discard any stale instance after class library recompile
	}

	init {
		verbosity = 2;
		enabled = true;
	}
	*get {
		// return existing, otherwise create one
		^logger ?? { logger = MDMiniLogger.new };
	}

	shouldLog { |msgVerbosity|
		var messageLevel, thresholdLevel, isOn;

		messageLevel   = (msgVerbosity ? 0).clip(0, 4);  // if nil default to 0
		thresholdLevel = (verbosity ? 0).clip(0, 4);     // the logger's current threshold
		isOn = (enabled ? true);
		// Print when:
		//  - logging is enabled, AND
		//  - the message is at least as important as the threshold (lower number = more important)
/*		^(isOn and: { messageLevel <= thresholdLevel });*/

// fix 0.3.2
^((enabled == true) and: { messageLevel <= thresholdLevel });

	}

	setverbosity { |newverbosity| verbosity = (newverbosity ? 0).clip(0, 4); ^verbosity }

	enable  { enabled = true;  ^enabled }

	disable { enabled = false; ^enabled }

	format {|argVerbosity, argLabel, argMessage |
		var line, logVerbosity, logLabel, logMessage;

		// check we have a verbosity
		logVerbosity = (argVerbosity ? 0).clip(0,4); // 0 if nil

		// check we have a label
		logLabel = argLabel ? "GENERIC";

		// check we have a message:
		logMessage = argMessage ? "";

		line = "[" ++ Date.getDate.stamp
		++ " | " ++ verbosityNames.at(logVerbosity)
		++ " | " ++ logLabel ++ "] "
		++ logMessage;
		^line;
	}

	log { |msgVerbosity, label, message|
		if (this.shouldLog(msgVerbosity)) {
			this.format(msgVerbosity, label, message).postln;
		};
		^this
	}

	// helpers

	error { |label, message| ^this.log(0, label, message) }  // ERROR
	warn  { |label, message| ^this.log(1, label, message) }  // WARN
	info  { |label, message| ^this.log(2, label, message) }  // INFO
	debug { |label, message| ^this.log(3, label, message) }  // DEBUG
	trace { |label, message| ^this.log(4, label, message) }  // TRACE

}