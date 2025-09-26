// index_vsc_entrypoints.scd
// Project Entry Points Index for LivePedalboardSuite
//
// This file lists the main entry points (scripts, bring-up routines, test harnesses, and editors)
// for all major components in the project. Use this as a reference for launching, testing, or exploring the system.
//
// -----------------------------------------------------------------------------
// System Bring-Up & Main Launchers
// -----------------------------------------------------------------------------
"LivePedalboardSystem/Start_LivePedalboardSystem.scd"      // Main system bring-up (Option B)
"MagicPedalboard/MagicPedalboardNew.scd"                   // Main pedalboard engine
"MagicPedalboardTestRunner.sc"                             // Test/bring-up runner

// -----------------------------------------------------------------------------
// CommandTree System: Editors, Tests, Utilities
// -----------------------------------------------------------------------------
"CommandTree/martinTreeEditor.scd"                         // Interactive tree editor (load, add, remove, save nodes)
"CommandTree/MDCommandSystemTest20250804.scd"              // CommandTree structure and navigation test
"CommandTree/MDCommandSystemTest20250812.scd"              // CommandTree structure and navigation test (string+fret)
"CommandTree/MDCommandBuilderTest.scd"                     // CommandBuilder navigation and queue test

// -----------------------------------------------------------------------------
// Utilities & Simulations
// -----------------------------------------------------------------------------
"utilities/Simulate_CommandTree_Queue_AddDelay.scd"        // Simulate queueing "/add/delay" via CommandTree
"utilities/Simulate_Step2_NavigateAndQueue_AddDelay.scd"   // Stepwise navigation and queueing
"utilities/Queue_AddDelay_DirectCanonical.scd"             // Direct canonical command queueing
"utilities/Inspect_And_Queue_AddDelay_AutoRoute.scd"       // Inspect tree and auto-route add/delay

// -----------------------------------------------------------------------------
// MagicPedalboard Troubleshooting & Demos
// -----------------------------------------------------------------------------
"MagicPedalboard/troubleshooting/MagicDisplayGUI_New_ServerBootAndProbe_v0.3.5.scd" // GUI, server, probe bring-up
"MagicPedalboard/troubleshooting/MagicDisplayGUI_NewPath_Step1_ServerAndMeters.scd" // Server/meter bring-up

// -----------------------------------------------------------------------------
// Test Harnesses & Acceptance Suites
// -----------------------------------------------------------------------------
"MagicPedalboard/MPBTest/Scripts/MPBTest_Run_HealthCheck.scd" // Health check script
"MagicPedalboard/MPBTest/Scripts/MPBTest_Run_OneGo.scd"       // One-go acceptance suite

// -----------------------------------------------------------------------------
// Miscellaneous & Example Scripts
// -----------------------------------------------------------------------------
"test 31tp8ve.scd"                                        // 31-tone scale test script

// -----------------------------------------------------------------------------
// Notes
// -----------------------------------------------------------------------------
// - For each entry, evaluate the file in VS Code to launch or test the corresponding component.
// - Most scripts assume you have run the main bring-up (Start_LivePedalboardSystem.scd) first.
// - See README.md and LivePedalboardSystem_README.md for further documentation and workflow details.