// test_MDMiniLogger.scd

m = MDMiniLogger.get;

m.setverbosity(0);
m.error(\TEST, "Error prints");
m.warn(\TEST,  "Warn prints");
m.info(\TEST,  "Info prints");
m.debug(\TEST, "Debug suppressed at INFO");
m.trace(\TEST, "Trace suppressed at INFO");

m.disable;  m.error(\TEST, "Should NOT print");
m.enable;   m.error(\TEST, "Should print again");

m.setverbosity(1);
m.error(\TEST, "Error prints");
m.warn(\TEST,  "Warn prints");
m.info(\TEST,  "Info prints");
m.debug(\TEST, "Debug suppressed at INFO");
m.trace(\TEST, "Trace suppressed at INFO");

m.disable;  m.error(\TEST, "Should NOT print");
m.enable;   m.error(\TEST, "Should print again");

m.setverbosity(2);
m.error(\TEST, "Error prints");
m.warn(\TEST,  "Warn prints");
m.info(\TEST,  "Info prints");
m.debug(\TEST, "Debug suppressed at INFO");
m.trace(\TEST, "Trace suppressed at INFO");

m.disable;  m.error(\TEST, "Should NOT print");
m.enable;   m.error(\TEST, "Should print again");

