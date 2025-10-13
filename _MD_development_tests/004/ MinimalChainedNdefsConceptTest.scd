// MinimalChainedNdefsConceptTest.scd


Ndef(\source).reshaping_(\elastic).source = { PinkNoise.ar(0.1)!6 };
Ndef(\alpha).reshaping_(\elastic).source = { \in.ar(0!6) };
Ndef(\beta ).reshaping_(\elastic).source = { \in.ar(0!6) };
Ndef(\gamma).reshaping_(\elastic).source = { \in.ar(0!6) };
Ndef(\delta).reshaping_(\elastic).source = { \in.ar(0!6) };

Ndef(\dest).reshaping_(\elastic).source = { \in.ar(0!6) };



Ndef(\source).play;
Ndef(\source).stop;

Ndef(\dest).play;


Ndef(\dest) <<> Ndef(\beta) <<> Ndef(\alpha) <<> Ndef(\source);