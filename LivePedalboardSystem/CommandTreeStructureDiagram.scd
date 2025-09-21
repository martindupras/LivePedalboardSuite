Command Tree Structure:

Root
├── Audio
│   ├── Source
│   │   ├── TestMelody
│   │   ├── Sine
│   │   ├── Noise
│   │   └── [Other sources...]
│   ├── Time-Based
│   │   ├── Delay
│   │   │   ├── Multi-Tap
│   │   │   ├── Ping-Pong
│   │   │   └── [Other delay types...]
│   │   └── Chorus
│   ├── Modulation
│   │   ├── Tremolo
│   │   ├── Phaser
│   │   └── Flanger
│   ├── Dynamics
│   │   ├── Compressor
│   │   └── Limiter
│   ├── Filter
│   │   ├── Lowpass
│   │   ├── Highpass
│   │   └── Bandpass
│   ├── Reverb
│   └── Drive
├── Chain
│   ├── Add Processor
│   ├── Remove Processor
│   ├── Swap Processors
│   ├── Bypass Processor
│   ├── Clear Chain
│   ├── Set Source
│   └── Print Chains
├── Switch
│   ├── Crossfade (default)
│   └── Crossfade (custom time)
├── Preset
│   ├── Save Preset
│   └── Load Preset
├── System
│   ├── Reset
│   ├── Health Check
│   └── Show Status