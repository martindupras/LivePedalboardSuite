// Install_QuietProxyMeters_Core.scd
// v0.1
// MD 20250923-1610

/* Purpose
   Install quiet meter taps inside Ndef(\chainA/\chainB) using .filter:
   - Low-rate sampling with Impulse.kr.
   - Threshold gate from UGens (no Boolean 'or:').
   - Sends '/ampA' '/ampB' only when above threshold.
   - No console prints by default.

   Style
   - var-first; Server.default.bind for server ops; no server.sync; descriptive names.
*/

(
var serverRef, sampleRateHz, postThreshold;
var ensureProxyAudio, installOrReplaceTap, installForProxy;

serverRef      = Server.default;
sampleRateHz   = 2.0;   // messages per second
postThreshold  = 0.02;  // ignore tiny levels

ensureProxyAudio = { |proxyName|
  Server.default.bind({
    Ndef(proxyName).ar(2); // ensure 2ch audio-rate proxy exists
  });
};

installOrReplaceTap = { |proxyName, oscPath|
  Server.default.bind({
    var proxyRef;
    proxyRef = Ndef(proxyName);
    proxyRef.ar(2);

    proxyRef.filter(\__meterTap__, { |inSig|
      var leftIn, rightIn, ampLeft, ampRight, ampMax, tick, gate;

      // robust channel fetch
      leftIn  = (inSig.size >= 1).if({ inSig[0] }, { 0.0 });
      rightIn = (inSig.size >= 2).if({ inSig[1] }, { leftIn });

      // per-channel level followers
      ampLeft  = Amplitude.kr(leftIn, 0.01, 0.15);
      ampRight = Amplitude.kr(rightIn, 0.01, 0.15);
      ampMax   = ampLeft.max(ampRight);     // <- UGen-safe combine

      // low-rate tick and gate when above threshold (UGen compare)
      tick = Impulse.kr(sampleRateHz);
      gate = tick * (ampMax > postThreshold); // 0 or tick

      // emit values only when above threshold
      SendReply.kr(gate, oscPath, [ampLeft, ampRight]);

      // pass-through audio unchanged
      inSig
    });
  });
};

installForProxy = { |proxyName, oscPath|
  ensureProxyAudio.(proxyName);
  installOrReplaceTap.(proxyName, oscPath);
};

installForProxy.(\chainA, '/ampA');
installForProxy.(\chainB, '/ampB');

"✅ Quiet proxy taps installed on Ndef(\\chainA/\\chainB). No console prints by default.".postln;
)
