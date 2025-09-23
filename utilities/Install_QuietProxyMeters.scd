// Install_QuietProxyMeters_NoRound.scd
// v0.1
// MD 20250923-1606

/* Purpose
   Install quiet meter taps inside Ndef(\chainA/\chainB) via .filter:
   - Low-rate sampling (Impulse.kr) and threshold gate (no rounding).
   - Sends OSC '/ampA' '/ampB' messages only when above threshold.
   - No console printing by default (no OSCdef printers are installed).

   Style
   - var-first; Server.default.bind for server ops; no server.sync; descriptive names.
*/

(
var serverRef, sampleRateHz, postThreshold, ensureProxyReady, installTapFor;

serverRef      = Server.default;
sampleRateHz   = 2.0;   // messages per second
postThreshold  = 0.02;  // ignore tiny levels

ensureProxyReady = { |proxyName|
  Server.default.bind({ Ndef(proxyName).ar(2) });
};

installTapFor = { |proxyName, oscPath|
  Server.default.bind({
    var proxyRef;
    proxyRef = Ndef(proxyName);
    proxyRef.ar(2);

    // Replace/insert a named filter; pass-through audio unchanged
    proxyRef.filter(\__meterTap__, { |inSig|
      var leftIn, rightIn, ampL, ampR, tick, gate;

      leftIn  = (inSig.size >= 1).if({ inSig[0] }, { 0 });
      rightIn = (inSig.size >= 2).if({ inSig[1] }, { leftIn });

      // Per-channel amplitude followers
      ampL = Amplitude.kr(leftIn, 0.01, 0.15);
      ampR = Amplitude.kr(rightIn, 0.01, 0.15);

      // Low-rate sampler and threshold gate (any channel above threshold triggers a send)
      tick = Impulse.kr(sampleRateHz);
      gate = tick * (((ampL > postThreshold) or: (ampR > postThreshold)).lag(0)); // boolean to 0/1

      // Send only when gate is 1
      SendReply.kr(gate, oscPath, [ampL, ampR]);

      // Pass-through
      inSig
    });
  });
};

// Ensure proxies exist and install taps
ensureProxyReady.(\chainA);
ensureProxyReady.(\chainB);
installTapFor.(\chainA, '/ampA');
installTapFor.(\chainB, '/ampB');

"✅ Quiet proxy meter taps installed on Ndef(\\chainA/\\chainB). No console prints by default.".postln;
)
