// DEMO20250923.scd ----------------------------


//Add delay → /add/delay
~nav_handleFret.(6,10);  // commands
~nav_handleFret.(5, 1);  // add
~nav_handleFret.(4, 1);  // delay (leaf → applies)


//Switch → /switch
~nav_handleFret.(6,10);  // commands
~nav_handleFret.(5, 3);  // switch (leaf → applies)


//Bypass delay ON / OFF
// ON
~nav_handleFret.(6,10);  // commands
~nav_handleFret.(5, 2);  // bypass
~nav_handleFret.(4, 1);  // delay
~nav_handleFret.(3, 2);  // on (leaf)
// OFF
~nav_handleFret.(6,10);
~nav_handleFret.(5, 2);
~nav_handleFret.(4, 1);
~nav_handleFret.(3, 3);  // off (leaf)


//Set source testmelody → /setSource/testmelody
~nav_handleFret.(6,10);  // commands
~nav_handleFret.(5, 4);  // setSource
~nav_handleFret.(4, 1);  // testmelody (leaf)
