// commands.scd

// Make a -6 dBFS sine (≈ -9 dB RMS) hit the top of the meter:
~hud_set.(\top, -9);

// Keep deep floor and straight-in-dB mapping:
~hud_set.(\floor, -60);
~hud_set.(\gamma, 1.0);

// Sanity print current settings:
~hud_print.();

// Preview expected UI value for an RMS dB (useful for tone calibration):
~hud_preview.(-9);   // -6 dBFS sine ≈ -9 dB RMS
~hud_preview.(-18);
