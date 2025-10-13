// workingReshapingNdefPassthrough.scd
(
Ndef(\pass).reshaping_(\elastic);
Ndef(\pass).source = {
    // Read the audio input named \in with an explicit width.
    // Pick a width that covers your expected max (e.g., 6 for hex).
    \in.ar(0 ! 6)   // returns silent zeros on channels with no signal
};
)


Ndef(\test, {PinkNoise.ar(0.2)!2});


Ndef(\pass) <<> Ndef(\test);
Ndef(\pass).play;


Ndef(\test, {PinkNoise.ar(0.2)});
Ndef(\test, {PinkNoise.ar(0.2)!2}); // should reshape... but doesn't
Ndef(\test, {PinkNoise.ar(0.2)!6});











//
//
// // WORKS!
// (
// Ndef(\pass).reshaping_(\elastic);
// Ndef(\pass).source = {
// 	// Read the audio input named \in with an explicit width.
// 	// Pick a width that covers your expected max (e.g., 6 for hex).
// 	\in.ar(0 ! 6)   // returns silent zeros on channels with no signal
// };
// )
//
//
// Ndef(\test, {PinkNoise.ar(0.2)!2});
//
//
// Ndef(\pass) <<> Ndef(\test);
// Ndef(\pass).play;
//
//
// Ndef(\test, {PinkNoise.ar(0.2)});
// Ndef(\test, {PinkNoise.ar(0.2)!2}); // should reshape... but doesn't
// Ndef(\test, {PinkNoise.ar(0.2)!6});
//
// // WORKS!
// (
// Ndef(\pass).reshaping_(\elastic);
// Ndef(\pass).source = {
// 	// Read the audio input named \in with an explicit width.
// 	// Pick a width that covers your expected max (e.g., 6 for hex).
// 	\in.ar(0 ! 6)   // returns silent zeros on channels with no signal
// };
// )
//
//
// Ndef(\test, {PinkNoise.ar(0.2)!2});
//
//
// Ndef(\pass) <<> Ndef(\test);
// Ndef(\pass).play;
//
//
// Ndef(\test, {PinkNoise.ar(0.2)});
// Ndef(\test, {PinkNoise.ar(0.2)!2}); // should reshape... but doesn't
// Ndef(\test, {PinkNoise.ar(0.2)!6});