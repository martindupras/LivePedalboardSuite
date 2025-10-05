// Disable_Ndef_Crossfade.scd
// v0.1.0
// MD 20251005-1828

/*
Purpose
- Remove NodeProxy fade/crossfade on \chainA/\chainB so we can see raw behavior.
Style
- var-first; lowercase; no server.sync.
*/

(
var setFade;
setFade = { |k, t|
    var nd = Ndef(k);
    if(nd.notNil) { nd.fadeTime = t };
    ("[Crossfade] " ++ k.asString ++ ".fadeTime=" ++ t).postln;
};
setFade.(\chainA, 0.0);
setFade.(\chainB, 0.0);
)